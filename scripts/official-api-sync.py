#!/usr/bin/env python3
"""CarRanking official APIs. No external Python dependencies.
OPINET: verified national product prices persisted only with supplied official certkey.
KEA: raw response is staged for review; no guessed vehicle-to-powertrain mapping.
"""
import datetime as dt
import json, os, pathlib, re, subprocess, sys, time, urllib.request, urllib.parse, urllib.error
out=pathlib.Path('official-economy-reports')
out.mkdir(exist_ok=True)
today=dt.datetime.now(dt.timezone(dt.timedelta(hours=9))).date()
status={'date_kst':today.isoformat(),'opinet':'not configured','kea':'not configured'}
def request_json(url):
    req=urllib.request.Request(url,headers={'User-Agent':'CarRanking/1.0 (+https://carranking.kr)','Accept':'application/json'})
    last=None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req,timeout=35) as resp:
                if resp.status!=200:raise ValueError(f'HTTP {resp.status}')
                raw=resp.read(2_000_000)
            return json.loads(raw.decode('utf-8-sig'))
        except (TimeoutError,urllib.error.URLError) as exc:
            last=exc
            if attempt<2:time.sleep(2*(attempt+1))
    raise last
def run_psql(sql):
    if not os.getenv('PGPASSWORD'):raise RuntimeError('missing SUPABASE_DB_PASSWORD')
    conn='host=aws-0-ap-northeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.ikhyadzboorscjwcrhcz sslmode=require'
    res=subprocess.run(['psql',conn,'-X','-v','ON_ERROR_STOP=1','-c',sql],capture_output=True,text=True)
    if res.returncode:raise RuntimeError('DB insert rejected: '+res.stderr[-700:])
def quote(x):return "'"+str(x).replace("'","''")+"'"
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
    try:
        if not url.startswith('https://') or not re.search(r'(energy\.or\.kr|data\.go\.kr)',urllib.parse.urlparse(url).hostname or ''):
            raise ValueError('KEA API host not allowlisted')
        qs=urllib.parse.parse_qsl(urllib.parse.urlparse(url).query,keep_blank_values=True)
        parsed_url=urllib.parse.urlparse(url)
        if parsed_url.path.rstrip('/').endswith('/CAREFF'):
            parsed_url=parsed_url._replace(path=parsed_url.path.rstrip('/')+'/CAREFF_LIST')
        qs=[(k,v) for k,v in qs if k.lower() not in ('servicekey','service_key')]
        qs.extend([('serviceKey',service_key),('pageNo','1'),('numOfRows','100'),('apiType','json')])
        address=urllib.parse.urlunparse(parsed_url._replace(query=urllib.parse.urlencode(qs)))
        data=request_json(address)
        if not isinstance(data,dict):raise ValueError('unexpected energy API response')
        # Do not store API keys, request URLs, or personal information in reports.
        (out/'kea-first-page-staging.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)[:200000],encoding='utf-8')
        status['kea']='staged first page; needs schema review and exact trim matching'
    except Exception as exc:
        status['kea']='failed'
        status['kea_error']=str(exc)[:250]
else:status['kea']='skipped: KEA_API_URL / KEA_SERVICE_KEY missing'
(out/'official-api-status.json').write_text(json.dumps(status,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(status,ensure_ascii=False))
if status['opinet']=='failed' or status['kea']=='failed':sys.exit(1)
