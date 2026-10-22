import unittest,sys,json
from pathlib import Path
r=Path(__file__).resolve().parent
sys.path.insert(0,str(Path.cwd()/'tool/task002'))
class Result(unittest.TextTestResult):
 def __init__(self,*a,**k):super().__init__(*a,**k);self.cases=[]
 def addSuccess(self,test):super().addSuccess(test);self.cases.append({'case':test.id(),'result':'PASS'})
 def addSubTest(self,test,subtest,outcome):
  super().addSubTest(test,subtest,outcome);self.cases.append({'case':str(subtest),'result':'PASS' if outcome is None else 'FAIL'})
suite=unittest.defaultTestLoader.discover('tool/task002',pattern='test_e2a_isolation.py')
with (r/'11-isolation-tests.log').open('w') as f:result=unittest.TextTestRunner(stream=f,verbosity=2,resultclass=Result).run(suite)
receipt={'result':'PASS' if result.wasSuccessful() else 'FAIL','methods':result.testsRun,'recorded_methods_and_subcases':len(result.cases),'cases':result.cases,'negative_networks_created':False,'unsafe_cases':'Mutated captured receipts only; real independent namespace used for correspondence checks','Auth_started':False,'SQL_executed':False}
(r/'12-isolation-tests.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({k:v for k,v in receipt.items() if k!='cases'},indent=2));sys.exit(0 if result.wasSuccessful() else 1)
