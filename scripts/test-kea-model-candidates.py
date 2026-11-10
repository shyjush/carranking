import importlib.util,pathlib,unittest
p=pathlib.Path(__file__).with_name('kea-model-candidates.py');s=importlib.util.spec_from_file_location('discovery',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
class Tests(unittest.TestCase):
 def setUp(self):
  self.makers=[{'id':'kia','name':'기아'},{'id':'hyundai','name':'현대'}]
  self.models=[{'name':n,'manufacturer_id':maker} for maker,n in [('kia','EV3'),('kia','EV6'),('hyundai','아이오닉 5'),('hyundai','아이오닉 6'),('hyundai','코나')]]
 def row(self,maker,label,year=2024):return {'CAR_KIND':'승용차','COMP_NM':maker,'MODEL_NM':label,'YEAR':year}
 def run_plan(self,rows):return m.discover(rows,self.makers,self.models)
 def test_observed_seven_groups(self):
  rows=[self.row('기아','EV3 항속형 2WD 17인치(nC)'),self.row('기아','EV6 항속형 2WD 개조차 19인치(nC)'),self.row('현대','아이오닉5 개조 항속형 RWD 19인치(nC)'),self.row('현대','아이오닉6(CE1) 기본형 RWD 18인치 25MY'),self.row('현대','코나 일렉트릭(N-Line) 19인치')]
  rows += [self.row('기아','스팅어(CK PE) 2.5T-GDI 2WD_'+str(i)+'인치',2020) for i in range(10)]
  rows += [self.row('현대','그랜드스타렉스(PE2)2.5디젤 '+str(i),2018) for i in range(4)]
  x=self.run_plan(rows);self.assertEqual((x['raw_candidate_count'],x['count'],x['excluded_count']),(7,2,5));self.assertEqual({r['model_candidate'] for r in x['candidates']},{'스팅어','그랜드스타렉스'});self.assertEqual(sum(r['records'] for r in x['candidates']),14);self.assertEqual(sum(r['records'] for r in x['excluded']),5)
  self.assertTrue(all(r['status']=='review_required_not_published' for r in x['candidates']))
 def test_brand_boundary(self):
  x=self.run_plan([self.row('현대','EV3(CD1)')]);self.assertEqual(x['count'],1)
 def test_no_prefix_collision(self):
  x=self.run_plan([self.row('기아','EV30(AB1)'),self.row('현대','코나새모델(AB1)')]);self.assertEqual(x['count'],2)
 def test_exact_existing_not_raw_candidate(self):self.assertEqual(self.run_plan([self.row('기아','EV3(SV1)')])['raw_candidate_count'],0)
 def test_unknown_unsupported_and_certification_year(self):
  x=self.run_plan([self.row('기아','스팅어(CK PE)',2020),{**self.row('현대','새모델(AB1)'),'CAR_KIND':'화물차'},self.row('외부','새모델(AB1)')]);self.assertEqual(x['count'],1);self.assertEqual(x['candidates'][0]['certification_years'],['2020']);self.assertNotIn('model_year',x['candidates'][0])
if __name__=='__main__':unittest.main()
