import ast,importlib.util,json,pathlib,unittest
from unittest.mock import patch
p=pathlib.Path(__file__).parent
spec=importlib.util.spec_from_file_location('verified',p/'kea-verified-variants.py');v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)
class Tests(unittest.TestCase):
 def setUp(self):
  self.mf=[{'id':'brand','name':'기아'}];self.models=[{'id':'model','manufacturer_id':'brand','name':'K5'}];self.gs=[{'id':'gen','car_model_id':'model','generation_code':'DL3','start_year':2019,'end_year':None}]
  self.r={'COMP_NM':'기아','MODEL_NM':'K5(DL3) 1.6T 17인치','YEAR':'2021','CAR_KIND':'승용차','FUEL_NM':'휘발유','ENGINE_DISPLACEMENT':'1598','CAR_TYPE':'내연기관','DISPLAY_EFF':'13.6'}
 def plan(self,rs):return v.plan({'items':rs,'totalCount':len(rs)},self.mf,self.models,self.gs)
 def test_explicit_code_only(self):
  self.assertEqual(len(self.plan([self.r])[0]),1)
  for name in ['K5 1.6T','K5(JF) 1.6T','BMW DL3','K5(DL30) 1.6T']:
   self.assertFalse(self.plan([{**self.r,'MODEL_NM':name}])[0])
 def test_no_wheel_arbitrary_selection(self):
  rows,s=self.plan([self.r,{**self.r,'MODEL_NM':'K5(DL3) 1.6T 18인치','DISPLAY_EFF':'13.0'}]);self.assertEqual(len(rows),2);self.assertNotEqual(rows[0]['powertrain_id'],rows[1]['powertrain_id'])
  self.assertFalse(self.plan([self.r,{**self.r,'DISPLAY_EFF':'13.0'}])[0])
 def test_duplicate_and_stable_ids(self):
  rows,s=self.plan([self.r,self.r]);self.assertEqual(s['duplicates'],1);self.assertEqual(rows[0]['spec_id'],self.plan([self.r])[0][0]['spec_id'])
 def test_certification_not_model_year(self):
  rows,_=self.plan([self.r]);self.assertIn('2021년 인증',rows[0]['efficiency']);self.assertNotIn('년식',rows[0]['efficiency'])
 def test_incomplete_fail_closed(self):
  with self.assertRaises(ValueError):v.plan({'items':[self.r],'totalCount':2},self.mf,self.models,self.gs)
 def test_conversion_and_wrong_brand(self):
  self.assertFalse(self.plan([{**self.r,'COMP_NM':'현대'}])[0]);self.assertFalse(self.plan([{**self.r,'MODEL_NM':'K5(DL3) 개조차'}])[0])
 def test_transaction_never_updates_legacy(self):
  rows,_=self.plan([self.r]);sql=v.sql(rows);self.assertNotIn('UPDATE ',sql);self.assertIn('ON CONFLICT(id) DO NOTHING',sql)
 def test_api_invalid_json_retry_and_page_guard(self):
  tree=ast.parse((p/'official-api-sync.py').read_text());defs=[n for n in tree.body if isinstance(n,(ast.Import,ast.ImportFrom,ast.FunctionDef))]
  ns={};exec(compile(ast.Module(body=defs,type_ignores=[]),'api','exec'),ns)
  class Response:
   status=200
   def __enter__(self):return self
   def __exit__(self,*a):pass
   def read(self,*a):return b'{"ok":true}'
  with patch.object(ns['urllib'].request,'urlopen',side_effect=[TimeoutError(),Response()]),patch.object(ns['time'],'sleep'):
   self.assertTrue(ns['request_json']('https://example.com')['ok'])
  with self.assertRaises(ValueError):ns['kea_body']({'response':{'body':{'pageNo':1}}},2)
  with self.assertRaises(ValueError):ns['kea_body']({'response':{'header':{'resultCode':'30'}}},1)
if __name__=='__main__':unittest.main()
