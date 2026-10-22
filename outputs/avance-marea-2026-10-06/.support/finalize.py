"""Add native print settings missing from the authoring API; inspect the saved outputs."""
from pathlib import Path
import json, re, zipfile, xml.etree.ElementTree as ET, hashlib

support=Path(__file__).resolve().parent
out=support.parent
book=out/'marea-avances-gantt.xlsx'
layout=json.loads((support/'layout.json').read_text())
data=json.loads((support/'inventory.json').read_text())
ns='http://schemas.openxmlformats.org/spreadsheetml/2006/main'
rel='http://schemas.openxmlformats.org/officeDocument/2006/relationships'
ET.register_namespace('x',ns);ET.register_namespace('r',rel)
q=lambda tag:f'{{{ns}}}{tag}'
N={'x':ns}

with zipfile.ZipFile(book) as z:
    entries={i.filename:(i,z.read(i.filename)) for i in z.infolist()}
    assert z.testzip() is None

# Keep schema order when adding print settings to the artifact-tool workbook.
sheet_order=['sheetPr','dimension','sheetViews','sheetFormatPr','cols','sheetData','sheetCalcPr',
 'sheetProtection','protectedRanges','scenarios','autoFilter','sortState','dataConsolidate',
 'customSheetViews','mergeCells','phoneticPr','conditionalFormatting','dataValidations',
 'hyperlinks','printOptions','pageMargins','pageSetup','headerFooter','rowBreaks','colBreaks',
 'customProperties','cellWatches','ignoredErrors','smartTags','drawing','legacyDrawing',
 'legacyDrawingHF','picture','oleObjects','controls','webPublishItems','tableParts','extLst']
order={t:i for i,t in enumerate(sheet_order)}
def insert_ordered(root,element):
    target=order[element.tag.split('}')[-1]]
    for i,child in enumerate(root):
        if order.get(child.tag.split('}')[-1],999)>target:
            root.insert(i,element);return
    root.append(element)

for num,name,last in [(1,'Cronograma',layout['totalRows']),(2,'Detalle',layout['detailLast'])]:
    filename=f'xl/worksheets/sheet{num}.xml'
    info,raw=entries[filename];root=ET.fromstring(raw)
    pr=root.find(q('sheetPr'))
    if pr is None:pr=ET.Element(q('sheetPr'));insert_ordered(root,pr)
    psp=pr.find(q('pageSetUpPr'))
    if psp is None:psp=ET.SubElement(pr,q('pageSetUpPr'))
    psp.set('fitToPage','1' if num==1 else '0')
    for tag in ['printOptions','pageMargins','pageSetup','headerFooter','rowBreaks']:
        for old in list(root.findall(q(tag))):root.remove(old)
    insert_ordered(root,ET.Element(q('printOptions'),{'gridLines':'0','headings':'0'}))
    insert_ordered(root,ET.Element(q('pageMargins'),{'left':'0.25','right':'0.25','top':'0.35','bottom':'0.35','header':'0.15','footer':'0.15'}))
    setup={'paperSize':'8','orientation':'landscape'}
    setup.update({'fitToWidth':'1','fitToHeight':'0'} if num==1 else {'scale':'100'})
    insert_ordered(root,ET.Element(q('pageSetup'),setup))
    footer=ET.Element(q('headerFooter'));ET.SubElement(footer,q('oddFooter')).text='&LMAREA&C&P / &N&R01 sep–18 nov 2026'
    insert_ordered(root,footer)
    if num==1:
        breaks=ET.Element(q('rowBreaks'),{'count':str(len(layout['pageBreaks'])),'manualBreakCount':str(len(layout['pageBreaks']))})
        for point in layout['pageBreaks']:
            assert not any(m['e']==point for m in layout['scheduleMap']),'Salto separa E y R'
            ET.SubElement(breaks,q('brk'),{'id':str(point),'min':'0','max':'16383','man':'1'})
        insert_ordered(root,breaks)
    entries[filename]=(info,ET.tostring(root,encoding='utf-8',xml_declaration=True))

info,raw=entries['xl/workbook.xml'];root=ET.fromstring(raw)
names=root.find(q('definedNames'))
if names is None:
    names=ET.Element(q('definedNames'))
    # definedNames follows sheets and precedes calcPr/extLst.
    sheets_index=list(root).index(root.find(q('sheets')))
    root.insert(sheets_index+1,names)
for old in list(names):
    if old.get('name') in ['_xlnm.Print_Titles','_xlnm.Print_Area']:names.remove(old)
for i,name,last,col,header in [(0,'Cronograma',layout['totalRows'],'S',9),(1,'Detalle',layout['detailLast'],'U',8)]:
    ET.SubElement(names,q('definedName'),{'name':'_xlnm.Print_Area','localSheetId':str(i)}).text=f"'{name}'!$A$1:${col}${last}"
    text=f"'{name}'!$1:${header}"
    if i==1:text+=f",'{name}'!$A:$C"
    ET.SubElement(names,q('definedName'),{'name':'_xlnm.Print_Titles','localSheetId':str(i)}).text=text
entries['xl/workbook.xml']=(info,ET.tostring(root,encoding='utf-8',xml_declaration=True))
temp=support/'finalized.xlsx'
with zipfile.ZipFile(temp,'w',compression=zipfile.ZIP_DEFLATED)as z:
    for filename,(info,raw)in entries.items():z.writestr(info,raw)
temp.replace(book)

with zipfile.ZipFile(book)as z:
    assert z.testzip() is None
    roots={n:ET.fromstring(z.read(f'xl/worksheets/sheet{i}.xml')) for i,n in [(1,'Cronograma'),(2,'Detalle')]}
    shared=[]
    if 'xl/sharedStrings.xml' in z.namelist():
        shared=[''.join(e.itertext()) for e in ET.fromstring(z.read('xl/sharedStrings.xml')).findall(q('si'))]
    def cells(root):return {c.get('r'):c for c in root.findall('.//x:sheetData/x:row/x:c',N)}
    cache={n:cells(r) for n,r in roots.items()}
    def value(sheet,address):
        c=cache[sheet].get(address)
        if c is None:return None
        if c.get('t')=='inlineStr':return ''.join(c.find(q('is')).itertext())
        v=c.find(q('v'))
        if v is None:return None
        if c.get('t')=='s':return shared[int(v.text)]
        if c.get('t') in ['str','e']:return v.text or ''
        return float(v.text) if v.text else None
    for t,m in zip(data['tasks'],layout['scheduleMap']):
        d=m['detailRow'];e=m['e'];r=m['r']
        assert value('Detalle',f'A{d}')==t['id']
        assert value('Detalle',f'D{d}')==t['title']
        assert value('Detalle',f'E{d}')==t['result']
        assert value('Detalle',f'F{d}')==t['state']
        assert value('Detalle',f'I{d}')==t['estimated']
        assert value('Cronograma',f'A{e}')==t['id']
        assert value('Cronograma',f'B{e}')==t['title']
        assert value('Cronograma',f'D{e}')==t['estimated']
        for c in ['J','K','L','M','N']:assert value('Detalle',f'{c}{d}') in [None,'']
        for c in ['D','F','G','H','I','J','K','L','M','N','O','P']:assert value('Cronograma',f'{c}{r}') in [None,'']
        for c in ['R','S']:assert value('Cronograma',f'{c}{e}') in [None,'']
        for c in ['G','H']:
            v=value('Detalle',f'{c}{d}');assert v==int(v),'Fecha con fracción horaria no prevista'
    assert roots['Cronograma'].find('.//x:pane',N).get('ySplit')=='9'
    assert roots['Cronograma'].find('.//x:pane',N).get('xSplit')=='3'
    assert roots['Detalle'].find('.//x:pane',N).get('ySplit')=='8'
    assert roots['Detalle'].find('.//x:pane',N).get('xSplit')=='4'
    cf=roots['Cronograma'].findall('x:conditionalFormatting/x:cfRule',N)
    assert len(cf)==2
    wb=ET.fromstring(z.read('xl/workbook.xml'))
    assert [s.get('name') for s in wb.findall('x:sheets/x:sheet',N)]==['Cronograma','Detalle']
    assert len(wb.findall('x:definedNames/x:definedName',N))==4
    tables=[n for n in z.namelist()if n.startswith('xl/tables/')and n.endswith('.xml')]
    assert tables,'Tabla filtrable ausente'
    assert ET.fromstring(z.read(tables[0])).find(q('autoFilter')) is not None
    assert not any(c.get('t')=='e'for d in cache.values()for c in d.values()),'Error de fórmula exportado'

md=(out/'marea-avances-detallados.md').read_text()
ids=re.findall(r'^### ([A-Z0-9]+\.\d{3}) — ',md,re.M)
assert ids==[t['id']for t in data['tasks']]
assert md.count('| R — Real |  |  |  |')==len(ids)
assert md.count('**Responsable asignado:** ____________________. **Realizado por:** ____________________.')==len(ids)
assert '18 de noviembre de 2026' in md
assert (out/'marea-avances-gantt.xlsx').stat().st_size>10000
report=json.loads((support/'verification.json').read_text())
report.update(savedXlsxVerified=True,printTitlesVerified=True,pairPreservingPageBreaks=len(layout['pageBreaks']),
    markdownVerified=True,wholeDateSerialsVerified=True,sha256=hashlib.sha256(book.read_bytes()).hexdigest(),
    workbookBytes=book.stat().st_size,markdownBytes=(out/'marea-avances-detallados.md').stat().st_size)
(support/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
inspect=out/'marea-avances-gantt.xlsx.inspect.ndjson'
if inspect.exists():inspect.replace(support/'export-inspection.ndjson')
print(json.dumps(report,ensure_ascii=False,indent=2))
