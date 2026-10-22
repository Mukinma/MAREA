"""Native print features absent from Artifact Tool; validate the saved workbook."""
from pathlib import Path
import json, zipfile, xml.etree.ElementTree as E, re
p=Path(__file__).resolve().parent;out=p.parent;book=out/'cronograma-marea-compacto.xlsx'
data=json.loads((p/'inventory.json').read_text());layout=json.loads((p/'layout.json').read_text())
ns='http://schemas.openxmlformats.org/spreadsheetml/2006/main';N={'x':ns};q=lambda t:f'{{{ns}}}{t}'
E.register_namespace('x',ns);E.register_namespace('r','http://schemas.openxmlformats.org/officeDocument/2006/relationships')
with zipfile.ZipFile(book) as z:entries={i.filename:(i,z.read(i.filename))for i in z.infolist()}
order={t:i for i,t in enumerate('sheetPr dimension sheetViews sheetFormatPr cols sheetData sheetCalcPr sheetProtection protectedRanges scenarios autoFilter sortState dataConsolidate customSheetViews mergeCells phoneticPr conditionalFormatting dataValidations hyperlinks printOptions pageMargins pageSetup headerFooter rowBreaks colBreaks customProperties cellWatches ignoredErrors smartTags drawing legacyDrawing legacyDrawingHF picture oleObjects controls webPublishItems tableParts extLst'.split())}
def insert(root,el):
 for i,c in enumerate(root):
  if order.get(c.tag.split('}')[-1],999)>order[el.tag.split('}')[-1]]:root.insert(i,el);return
 root.append(el)
for i in [1,2]:
 file=f'xl/worksheets/sheet{i}.xml';info,raw=entries[file];r=E.fromstring(raw)
 pr=r.find(q('sheetPr'))
 if pr is None:pr=E.Element(q('sheetPr'));insert(r,pr)
 E.SubElement(pr,q('pageSetUpPr'),{'fitToPage':'1' if i==1 else '0'})
 for tag in ['printOptions','pageMargins','pageSetup','headerFooter','rowBreaks']:
  for old in list(r.findall(q(tag))):r.remove(old)
 insert(r,E.Element(q('printOptions'),{'gridLines':'0','headings':'0'}))
 insert(r,E.Element(q('pageMargins'),{'left':'0.25','right':'0.25','top':'0.35','bottom':'0.35','header':'0.15','footer':'0.15'}))
 cfg={'paperSize':'8','orientation':'landscape'};cfg.update({'fitToWidth':'1','fitToHeight':'0'}if i==1 else{'scale':'100'})
 insert(r,E.Element(q('pageSetup'),cfg));foot=E.Element(q('headerFooter'));E.SubElement(foot,q('oddFooter')).text='&LMAREA&C&P / &N&R01 sep–18 nov 2026';insert(r,foot)
 if i==1:
  breaks=E.Element(q('rowBreaks'),{'count':str(len(layout['pageBreaks'])),'manualBreakCount':str(len(layout['pageBreaks']))})
  for b in layout['pageBreaks']:
   assert not any(m['e']==b for m in layout['scheduleMap'])
   E.SubElement(breaks,q('brk'),{'id':str(b),'min':'0','max':'16383','man':'1'})
  insert(r,breaks)
 entries[file]=(info,E.tostring(r,encoding='utf-8',xml_declaration=True))
info,raw=entries['xl/workbook.xml'];r=E.fromstring(raw);names=r.find(q('definedNames'))
if names is None:names=E.Element(q('definedNames'));r.insert(list(r).index(r.find(q('sheets')))+1,names)
for i,name,last,col,header in [(0,'Cronograma',299,'T',9),(1,'Detalle',150,'R',8)]:
 E.SubElement(names,q('definedName'),{'name':'_xlnm.Print_Area','localSheetId':str(i)}).text=f"'{name}'!$A$1:${col}${last}"
 E.SubElement(names,q('definedName'),{'name':'_xlnm.Print_Titles','localSheetId':str(i)}).text=f"'{name}'!$1:${header}"+(f",'{name}'!$A:$D"if i else'')
entries['xl/workbook.xml']=(info,E.tostring(r,encoding='utf-8',xml_declaration=True))
tmp=p/'print-settings.xlsx'
with zipfile.ZipFile(tmp,'w',compression=zipfile.ZIP_DEFLATED)as z:
 for file,(info,raw)in entries.items():z.writestr(info,raw)
tmp.replace(book)
with zipfile.ZipFile(book)as z:
 assert z.testzip() is None
 roots={s:E.fromstring(z.read(f'xl/worksheets/sheet{i}.xml'))for i,s in [(1,'Cronograma'),(2,'Detalle')]}
 shared=[''.join(s.itertext())for s in E.fromstring(z.read('xl/sharedStrings.xml')).findall(q('si'))]if'xl/sharedStrings.xml'in z.namelist()else[]
 cells={s:{c.get('r'):c for c in r.findall('.//x:sheetData/x:row/x:c',N)}for s,r in roots.items()}
 def value(s,a):
  c=cells[s].get(a)
  if c is None:return None
  if c.get('t')=='inlineStr':return ''.join(c.find(q('is')).itertext())
  v=c.find(q('v'))
  if v is None:return None
  if c.get('t')=='s':return shared[int(v.text)]
  if c.get('t') in ['str','e']:return v.text or''
  return float(v.text)if v.text else None
 for t,m in zip(data['tasks'],layout['scheduleMap']):
  d=m['detailRow'];e=m['e'];r=m['r']
  for col,key in [('A','id'),('B','stageName'),('C','moduleName'),('D','title'),('E','result'),('F','state'),('K','role'),('L','assigned'),('P','close'),('Q','note')]:assert value('Detalle',f'{col}{d}')==t[key],(t['id'],col)
  assert not value('Detalle',f'M{d}')
  assert value('Detalle',f'R{d}')=='\n'.join(t['sources'])
  assert value('Detalle',f'I{d}')==t['estimated']
  assert value('Cronograma',f'A{e}')==t['id'];assert value('Cronograma',f'C{e}')==t['title'];assert value('Cronograma',f'F{e}')==t['state'];assert value('Cronograma',f'S{e}')==t['assigned']
  assert value('Cronograma',f'E{e}')==t['estimated']
  if t['state']=='Completado':assert value('Cronograma',f'E{r}')==t['estimated'];assert value('Detalle',f'J{d}')==t['estimated']
  else:assert not value('Cronograma',f'E{r}');assert not value('Detalle',f'J{d}')
  for j,col in enumerate('GHIJKLMNOPQ'):
   assert(value('Cronograma',f'{col}{e}')==1)==(t['start']-1<=j<=t['end']-1)
   assert(value('Cronograma',f'{col}{r}')==1)==(t['state']=='Completado'and t['start']-1<=j<=t['end']-1)
  for col in['G','H']:
   v=value('Detalle',f'{col}{d}');assert v==int(v)
 assert roots['Cronograma'].find('.//x:pane',N).get('ySplit')=='9'
 assert roots['Detalle'].find('.//x:pane',N).get('ySplit')=='8'
 assert len(roots['Cronograma'].findall('x:conditionalFormatting/x:cfRule',N))==2
 assert len(roots['Detalle'].findall('x:dataValidations/x:dataValidation',N))==3
 assert not any(c.get('t')=='e'for cc in cells.values()for c in cc.values())
 # Confirm all merged regions are disjoint, including headings and paired task fields.
 def coord(a):
  m=re.fullmatch(r'([A-Z]+)(\d+)',a);col=0
  for ch in m[1]:col=col*26+ord(ch)-64
  return col,int(m[2])
 occupied=set()
 for el in roots['Cronograma'].findall('x:mergeCells/x:mergeCell',N):
  a,b=el.get('ref').split(':');x1,y1=coord(a);x2,y2=coord(b)
  for x in range(x1,x2+1):
   for y in range(y1,y2+1):assert(x,y)not in occupied;occupied.add((x,y))
 table=next(f for f in z.namelist()if f.startswith('xl/tables/')and f.endswith('.xml'));assert E.fromstring(z.read(table)).find(q('autoFilter'))is not None
md=(out/'cronograma-marea-compacto.md').read_text()
assert re.findall(r'^### ([A-Z]+-\d{2}) — ',md,re.M)==[t['id']for t in data['tasks']]
for t in data['tasks']:
 block=md.split(f"### {t['id']} — ")[1].split('\n### ')[0].split('\n## ')[0]
 assert t['title']in block and t['result']in block and t['note']in block and f"**Responsable asignado:** {t['assigned']}"in block
 assert f"| R | {t['real']if t['real']is not None else''} |"in block
report=json.loads((p/'verification.json').read_text());report.update(savedXlsxVerified=True,savedMarkdownVerified=True,mergedRegionsDisjoint=True,printSettingsVerified=True,pairPreservingBreaks=len(layout['pageBreaks']))
(p/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
inspect=out/'cronograma-marea-compacto.xlsx.inspect.ndjson'
if inspect.exists():inspect.replace(p/'export-inspection.ndjson')
print(json.dumps(report,ensure_ascii=False,indent=2))
