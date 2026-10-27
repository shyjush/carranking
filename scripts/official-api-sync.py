#!/usr/bin/env python3
"""CarRanking official APIs. No external Python dependencies.
OPINET: verified national product prices persisted only with supplied official certkey.
KEA: raw response is staged for review; no guessed vehicle-to-powertrain mapping.
"""
import socket
import datetime as dt
import json, os, pathlib, re, subprocess, sys, time, urllib.request, urllib.parse, urllib.error
out=pathlib.Path('official-economy-reports')
out.mkdir(exist_ok=True)
today=dt.datetime.now(dt.timezone(dt.timedelta(hours=9))).date()
status={'date_kst':today.isoformat(),'opinet':'not configured','kea':'not configured'}
def request_json(url):
    req=urllib.request.Request(url,headers={'User-Agent':'CarRanking/1.0 (+https://carranking.kr)','Accept':'application/json'})
    last=None
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req,timeout=20) as resp:
                if resp.status!=200:raise ValueError(f'HTTP {resp.status}')
                raw=resp.read(2_000_001)
                if len(raw)>2_000_000:raise ValueError('response too large')
            return json.loads(raw.decode('utf-8-sig'))
        except (TimeoutError,urllib.error.URLError,json.JSONDecodeError,UnicodeDecodeError,ConnectionError) as exc:
            last=exc
            if isinstance(exc,urllib.error.HTTPError) and exc.code not in (408,429,500,502,503,504): raise ValueError(f'HTTP {exc.code}') from None
            if attempt<3:time.sleep(2**attempt)
    raise RuntimeError('official API unavailable after 4 attempts ('+type(last).__name__+')') from None
def run_psql(sql):
    if not os.getenv('PGPASSWORD'):raise RuntimeError('missing SUPABASE_DB_PASSWORD')
    conn='host=aws-0-ap-northeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.ikhyadzboorscjwcrhcz sslmode=require'
    res=subprocess.run(['psql',conn,'-X','-v','ON_ERROR_STOP=1','-c',sql],capture_output=True,text=True)
    if res.returncode:raise RuntimeError('DB insert rejected: '+res.stderr[-700:])
def quote(x):return "'"+str(x).replace("'","''")+"'"
def kea_body(response,page):
    if not isinstance(response,dict):raise ValueError('unexpected official response')
    envelope=response.get('response',{})
    header=envelope.get('header',{})
    if str(header.get('resultCode','00')) not in ('00','0','INFO-000'):raise ValueError('official API result code '+str(header.get('resultCode'))[:20])
    body=envelope.get('body',{})
    if not isinstance(body,dict):raise ValueError('missing official body')
    if body.get('pageNo') is not None and int(body['pageNo'])!=page:raise ValueError('repeated or wrong official page')
    return body
key=os.getenv('OPINET_API_KEY','').strip()
if key:
    try:
        url='https://www.opinet.co.kr/api/avgAllPrice.do?'+urllib.parse.urlencode({'out':'json','certkey':key})
        data=request_json(url)
        oils=data.get('RESULT',{}).get('OIL',[])
        codes={'B027':'gas','D047':'diesel','K015':'lpg'}
        parsed={}
        for row in oils:
            code=row.get('PRODCD')
            if code not in codes:continue
            value=float(row['PRICE'])
            rawdate=str(row['TRADE_DT'])
            date=dt.datetime.strptime(rawdate,'%Y%m%d').date()
            if not 200<=value<=5000 or not dt.timedelta(0)<=today-date<=dt.timedelta(days=4):
                raise ValueError('stale or invalid official fuel price')
            parsed[codes[code]]=(value,date)
        if set(parsed)!=set(codes.values()):raise ValueError('missing required official product prices')
        values=','.join(f"({quote(k)},{price},{quote(date.isoformat())},'https://www.opinet.co.kr/api/avgAllPrice.do')" for k,(price,date) in parsed.items())
        sql=f"""INSERT INTO public.official_fuel_prices(fuel_type,price_krw,price_date,source_url)
        VALUES {values}
        ON CONFLICT(fuel_type) DO UPDATE SET price_krw=excluded.price_krw,price_date=excluded.price_date,source_url=excluded.source_url,updated_at=now()
        WHERE public.official_fuel_prices.price_date<=excluded.price_date;"""
        run_psql(sql)
        status['opinet']='updated'
        status['opinet_prices']={k:{'won_per_litre':v[0],'date':v[1].isoformat()} for k,v in parsed.items()}
    except Exception as exc:
        status['opinet']='failed'
        status['opinet_error']=str(exc)[:250]
else:status['opinet']='skipped: OPINET_API_KEY is not configured'
url=os.getenv('KEA_API_URL','').strip()
service_key=os.getenv('KEA_SERVICE_KEY','').strip()
if url and service_key:
    # A failed run must never consume a previous run's staging file.
    (out/'kea-all-pages-staging.json').unlink(missing_ok=True)
    try:
        if not url.startswith('https://') or not any((urllib.parse.urlparse(url).hostname or '')==h or (urllib.parse.urlparse(url).hostname or '').endswith('.'+h) for h in ('energy.or.kr','data.go.kr')):
            raise ValueError('KEA API host not allowlisted')
        qs=urllib.parse.parse_qsl(urllib.parse.urlparse(url).query,keep_blank_values=True)
        parsed_url=urllib.parse.urlparse(url)
        if parsed_url.path.rstrip('/').endswith('/CAREFF'):
            parsed_url=parsed_url._replace(path=parsed_url.path.rstrip('/')+'/CAREFF_LIST')
        qs=[(k,v) for k,v in qs if k.lower() not in ('servicekey','service_key','pageno','numofrows','apitype')]
        qs.extend([('serviceKey',urllib.parse.unquote(service_key)),('pageNo','1'),('numOfRows','100'),('apiType','json')])
        address=urllib.parse.urlunparse(parsed_url._replace(query=urllib.parse.urlencode(qs)))
        first=request_json(address)
        if not isinstance(first,dict):raise ValueError('unexpected energy API response')
        body=kea_body(first,1)
        status['kea_pages']=1
        first_items=body.get('items',{}).get('item',[])
        if not isinstance(first_items,list):raise ValueError('expected official list response')
        total=int(body.get('totalCount',0))
        if total<1 or total>100000:raise ValueError('invalid official totalCount')
        all_items=list(first_items)
        per_page=100
        for page in range(2,min(1+(total+per_page-1)//per_page,1001)):
            params=[(k,str(page) if k=='pageNo' else v) for k,v in qs]
            next_url=urllib.parse.urlunparse(parsed_url._replace(query=urllib.parse.urlencode(params)))
            response=request_json(next_url)
            page_body=kea_body(response,page)
            if int(page_body.get('totalCount',0))!=total:raise ValueError('official totalCount changed during pagination')
            chunk=page_body.get('items',{}).get('item',[])
            if not chunk:raise ValueError('empty official page')
            status['kea_pages']=page
            if not isinstance(chunk,list):raise ValueError('unexpected subsequent official page')
            all_items.extend(chunk)
        if len(all_items)!=total:raise ValueError(f'incomplete official pages: {len(all_items)} of {total}')
        tmp=out/'kea-all-pages-staging.tmp'
        tmp.write_text(json.dumps({'items':all_items,'totalCount':total,'fetched_at':dt.datetime.now(dt.timezone.utc).isoformat(),'pages':status['kea_pages']},ensure_ascii=False),encoding='utf-8')
        tmp.replace(out/'kea-all-pages-staging.json')
        status['kea']='all official pages staged for strict model/trim matching'
        status['kea_records']=len(all_items)
    except Exception as exc:
        status['kea']='failed'
        status['kea_error']=str(exc)[:250]
else:status['kea']='skipped: KEA_API_URL / KEA_SERVICE_KEY missing'
(out/'official-api-status.json').write_text(json.dumps(status,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(status,ensure_ascii=False))
if status['opinet']=='failed' or status['kea']=='failed':sys.exit(1)
