#!/usr/bin/env python3
"""One-time public original review. Extracted fields are NOT validated market snapshots."""
import gzip,json,pathlib,re,hashlib,urllib.request,urllib.error,concurrent.futures,datetime,threading,html
from html.parser import HTMLParser
P=pathlib.Path('research/completion-20261028');rows=json.loads((P/'individual-candidates.json').read_text() if (P/'individual-candidates.json').exists() else gzip.decompress((P/'individual-candidates.json.gz').read_bytes()));sources={c['key']:c for r in rows for c in r['candidates']};blocked=set();lock=threading.Lock()
class Parser(HTMLParser):
 def __init__(self):super().__init__();self.skip=0;self.text=[];self.tags=[];self.meta={};self.heading=[];self.inheading=False
 def handle_starttag(self,t,a):
  attrs=dict(a)
  if t in ['script','style','noscript']:self.skip+=1
  if t=='meta':self.meta[attrs.get('property',attrs.get('name',''))]=attrs.get('content','')
  if t in ['h1','h2','h3']:self.inheading=True
 def handle_endtag(self,t):
  if t in ['script','style','noscript']:self.skip=max(0,self.skip-1)
  if t in ['h1','h2','h3']:self.inheading=False
 def handle_data(self,d):
  if not self.skip:self.text.append(d)
  if self.inheading:self.heading.append(d.strip())
def redact(t):
 t=re.sub(r'\b[A-HJ-NPR-Z0-9]{17}\b','[차대번호 생략]',t);t=re.sub(r'\d{2,3}[가-힣]\d{4}','[차량번호 생략]',t);t=re.sub(r'\b0\d{1,3}[- ]\d{3,4}[- ]\d{4}\b','[연락처 생략]',t);return t
count=0

def get(item):
 key,c=item;u=c['url'];host=urllib.parse.urlsplit(u).hostname;family='bobaedream.co.kr' if host.endswith('bobaedream.co.kr') else 'kbchachacha.com' if host.endswith('kbchachacha.com') else host
 with lock:
  if family in blocked:return dict(key=key,url=u,decision='not_fetched_host_block',reason='이 호스트의 접근 제한 확인 후 추가 요청 중단')
 stamp=datetime.datetime.now(datetime.timezone.utc).isoformat()
 try:
  response=urllib.request.urlopen(urllib.request.Request(u,headers={'User-Agent':'Mozilla/5.0'}),timeout=16);b=response.read(4000000)
  encoding=response.headers.get_content_charset() or 'utf-8';s=b.decode(encoding,'replace');p=Parser();p.feed(s);txt=re.sub(r'\s+',' ',html.unescape(' '.join(p.text))).strip()
  if re.search(r'verify you are human|checking your browser|automated quer|access denied|비정상적인 접근|자동화된 요청',txt[:3000],re.I):
   with lock:blocked.add(family)
   return dict(key=key,url=u,status=response.status,fetched_at=stamp,sha256=hashlib.sha256(b).hexdigest(),decision='site_access_block',reason=redact(txt[:180]))
  pos=next((m.start() for m in re.finditer(r'\d[\d,]*\s*(?:km|㎞)',txt,re.I)),0);lead=txt[max(0,pos-130):pos+220]
  if key.startswith('boba-') and '[판매완료]' in txt:status='sold'
  elif re.search(r'판매완료|계약완료',lead):status='sold_or_contracted'
  else:status='sale_status_unconfirmed'
  price=re.search(r'(\d[\d,]*)\s*만원',txt[pos:pos+160]);km=re.search(r'(\d[\d,]*)\s*(?:km|㎞)',txt[pos:pos+50],re.I)
  facts={}
  for field,pat in [('year',r'연식.{0,65}'),('mileage',r'주행거리.{0,45}'),('condition',r'(?:사고/침수유무|사고유무|보험이력).{0,70}'),('drivetrain',r'(?:구동방식|구륜방식|굴림방식).{0,45}')]:facts[field]=[redact(m.group()) for m in list(re.finditer(pat,txt))[:2]]
  vins=sorted(set(re.findall(r'\b(?:WBA|WBS|WAU|WVG|WVW|WP0|WPO|WDB|WDD|KMH|KNA|KN[A-Z]|YV1|YV4|JTH|JTJ|JTN|JTM|KLY)[A-HJ-NPR-Z0-9]{14}\b',s)))
  return dict(key=key,url=u,status=response.status,fetched_at=stamp,sha256=hashlib.sha256(b).hexdigest(),title=redact(p.meta.get('og:title',c['title'])),headings=[redact(h)for h in p.heading if h][:7],lead=redact(lead),extracted_price_krw=int(price[1].replace(',',''))*10000 if price else None,extracted_mileage_km=int(km[1].replace(',',''))if km else None,listing_status=status,facts=facts,vehicle_identity_hashes=[hashlib.sha256(v.encode()).hexdigest()for v in vins],decision='direct_original_review_required',characters=len(txt))
 except urllib.error.HTTPError as e:
  if e.code==429:
   with lock:blocked.add(family)
  return dict(key=key,url=u,fetched_at=stamp,status=e.code,decision='http_error',reason=str(e))
 except Exception as e:return dict(key=key,url=u,fetched_at=stamp,decision='fetch_error',reason=str(e))
results=[]
with concurrent.futures.ThreadPoolExecutor(5) as pool:
 for r in pool.map(get,sources.items()):
  results.append(r)
  if len(results)%20==0:print(json.dumps({'processed':len(results),'total':len(sources),'http200':sum(x.get('status')==200 for x in results),'blocked_hosts':sorted(blocked)}),flush=True)
  (P/'individual-originals.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'finished':len(results),'http200':sum(x.get('status')==200 for x in results),'sold':sum(x.get('listing_status','').startswith('sold')for x in results),'errors':sum(x.get('status')!=200 for x in results)}),flush=True)
