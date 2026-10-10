from pathlib import Path
import csv, json, shutil, sys
from metrics import normalize_rows

output_directory = 'analytics-export'
if len(sys.argv) > 1:
    output_directory = sys.argv[1]
OUT=Path(output_directory).resolve()
PACKAGE=OUT/'ENAd_Flutter_PowerBI'
REPORT=PACKAGE/'ENAd.Report'
MODEL=PACKAGE/'ENAd.SemanticModel'
BASE='https://developer.microsoft.com/json-schemas/fabric/item/report/'

def save(path, data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')

def schema(part,version='1.0.0'):
    return BASE+'definition/'+part+'/'+version+'/schema.json'

measures={
 'Actividades': 'COALESCE(CALCULATE(COUNTROWS(Eventos), Eventos[name] = "activity_selected"), 0)',
 'Biblioteca': 'COALESCE(CALCULATE([Actividades], Eventos[source] = "library"), 0)',
 'Propias': 'COALESCE(CALCULATE([Actividades], Eventos[source] = "custom"), 0)',
 'Porcentaje biblioteca': 'DIVIDE([Biblioteca], [Actividades])',
 'Porcentaje propias': 'DIVIDE([Propias], [Actividades])',
 'Frecuencia actividad': '[Actividades]',
 'Participacion actividad': 'DIVIDE([Actividades], CALCULATE([Actividades], REMOVEFILTERS(Eventos[title])))',
 'Agrupaciones': 'COALESCE(CALCULATE(COUNTROWS(Eventos), Eventos[name] = "grouping_method_selected"), 0)',
 'Muestra agrupacion': '[Agrupaciones]',
 'Estado actividades': 'IF([Actividades] = 0, "Sin eventos Flutter verificables", "Datos Flutter disponibles")',
 'Estado agrupacion': 'IF([Agrupaciones] = 0, "Sin eventos Flutter verificables", "Datos Flutter disponibles")',
}

with (OUT/'flutter_bq_events.csv').open(encoding='utf-8-sig',newline='') as file:
    rows=normalize_rows(list(csv.DictReader(file)))
columns=['date','name','title','subject','source','method','classSize','count','platform']

def mvalue(value, column):
    if column in ['count','classSize']:
        if value == '': return 'null'
        return str(int(value))
    return '"'+str(value).replace('"','""')+'"'

types=[]
for column in columns:
    dtype='text'
    if column in ['count','classSize']: dtype='nullable number'
    types.append(column+' = '+dtype)
records=['{'+', '.join(mvalue(row[column],column) for column in columns)+'}' for row in rows]
expression='let\n    Source = #table(type table ['+', '.join(types)+'], {'+', '.join(records)+'})\nin\n    Source'
model_columns=[]
for column in columns:
    dtype='string'
    summary='none'
    if column in ['count','classSize']: dtype='int64'
    model_columns.append({'name':column,'dataType':dtype,'sourceColumn':column,'summarizeBy':summary})
model_measures=[]
for name,expression_dax in measures.items():
    measure={'name':name,'expression':expression_dax}
    if name.startswith('Porcentaje') or name.startswith('Participacion'): measure['formatString']='0.0%'
    model_measures.append(measure)
save(MODEL/'model.bim',{'name':'ENAdFlutter','compatibilityLevel':1567,'model':{
    'culture':'es-CO','tables':[{'name':'Eventos','columns':model_columns,'measures':model_measures,
    'partitions':[{'name':'Eventos','mode':'import','source':{'type':'m','expression':expression.splitlines()}}]}]}})
save(MODEL/'definition.pbism',{'$schema':'https://developer.microsoft.com/json-schemas/fabric/item/semanticModel/definitionProperties/1.0.0/schema.json','version':'1.0','settings':{}})
save(PACKAGE/'ENAd.pbip',{'$schema':'https://developer.microsoft.com/json-schemas/fabric/pbip/pbipProperties/1.0.0/schema.json',
    'version':'1.0','artifacts':[{'report':{'path':'ENAd.Report'}}],'settings':{'enableAutoRecovery':True}})
save(REPORT/'definition.pbir',{'$schema':BASE+'definitionProperties/2.0.0/schema.json','version':'4.0',
    'datasetReference':{'byPath':{'path':'../ENAd.SemanticModel'}}})
save(REPORT/'definition/version.json',{'$schema':schema('versionMetadata'),'version':'2.0.0'})
save(REPORT/'definition/report.json',{'$schema':schema('report','3.0.0'),'themeCollection':{}})
pages=['bq4','bq11','bq14']
save(REPORT/'definition/pages/pages.json',{'$schema':schema('pagesMetadata'),'pageOrder':pages,'activePageName':'bq4'})

def projection(field,measure=False):
    kind='Column'
    if measure: kind='Measure'
    return {'field':{kind:{'Expression':{'SourceRef':{'Entity':'Eventos'}},'Property':field}},
            'queryRef':'Eventos.'+field,'nativeQueryRef':field}

def visual(page,name,kind,x,y,width,height,roles=None,title=None,text=None):
    config={'visualType':kind}
    if roles:
        config['query']={'queryState':{role:{'projections':[projection(field,is_measure) for field,is_measure in fields]}
            for role,fields in roles.items()}}
    if name == 'ranking':
        config['query']['sortDefinition'] = {'sort': [{'field': projection('Frecuencia actividad', True)['field'], 'direction': 'Descending'}], 'isDefaultSort': False}
    if title:
        config['visualContainerObjects']={'title':[{'properties':{'show':{'expr':{'Literal':{'Value':'true'}}},
            'text':{'expr':{'Literal':{'Value':"'"+title+"'"}}}}}]}
    if text:
        config['objects']={'general':[{'properties':{'paragraphs':[{'textRuns':[{'value':text,
            'textStyle':{'fontSize':'16pt','fontFamily':'Segoe UI'}}]}]}}]}
    save(REPORT/('definition/pages/'+page+'/visuals/'+name+'/visual.json'),{
      '$schema':schema('visualContainer'),'name':name,'position':{'x':x,'y':y,'z':0,'width':width,'height':height,'tabOrder':0},'visual':config})

titles={'bq4':'BQ #4 · Biblioteca y actividades propias','bq11':'BQ #11 · Actividades más usadas','bq14':'BQ #14 · Métodos de agrupación'}
cutoff=json.loads((OUT/'metrics_cutoff.json').read_text())['extractedAt']
for page in pages:
    save(REPORT/('definition/pages/'+page+'/page.json'),{'$schema':schema('page'),'name':page,
        'displayName':titles[page],'displayOption':'FitToPage','width':1280,'height':720})
    visual(page,'heading','textbox',24,16,1220,58,text=titles[page])
    visual(page,'cutoff','textbox',24,638,1220,62,text='Corte: '+cutoff+' · Solo platform=flutter. Datos históricos sin origen verificable excluidos. La selección de método no mide efectividad educativa.')
    visual(page,'status','card',24,86,880,68,{'Values':[('Estado actividades',True)]})
    visual(page,'period','slicer',930,86,324,68,{'Values':[('date',False)]},'Fecha')
    if page=='bq4':
        visual(page,'library','card',24,170,290,100,{'Values':[('Biblioteca',True)]},'Actividades de biblioteca')
        visual(page,'custom','card',336,170,290,100,{'Values':[('Propias',True)]},'Actividades propias')
        visual(page,'share','card',648,170,290,100,{'Values':[('Porcentaje biblioteca',True)]},'Porcentaje de biblioteca')
        visual(page,'custom_share','card',960,170,294,100,{'Values':[('Porcentaje propias',True)]},'Porcentaje propias')
        visual(page,'usage','clusteredColumnChart',24,290,800,320,{'Category':[('source',False)],'Y':[('Actividades',True)]},'Origen de actividades planeadas')
        visual(page,'subject','slicer',847,300,390,160,{'Values':[('subject',False)]},'Materia')
    elif page=='bq11':
        visual(page,'ranking','clusteredBarChart',24,174,800,425,{'Category':[('title',False)],'Y':[('Frecuencia actividad',True)]},'Ranking de actividades')
        visual(page,'details','tableEx',847,174,390,425,{'Values':[('title',False),('Frecuencia actividad',True),('Participacion actividad',True)]},'Frecuencia y participación')
    else:
        visual(page,'status','card',24,86,880,68,{'Values':[('Estado agrupacion',True)]})
        visual(page,'methods','clusteredColumnChart',24,174,800,425,{'Category':[('method',False)],'Y':[('Agrupaciones',True)]},'Métodos observados')
        visual(page,'sample','tableEx',847,174,390,425,{'Values':[('subject',False),('classSize',False),('method',False),('Muestra agrupacion',True)]},'Materia, tamaño de clase y muestra')

(OUT/'medidas_powerbi.dax').write_text('\n\n'.join(name+' = '+expr for name,expr in measures.items()),encoding='utf-8')
extraction=json.loads((OUT/'metrics_cutoff.json').read_text())
readme=f'''# ENAd Flutter · BQs #4, #11 y #14

Proyecto editable de Power BI con tres páginas y medidas DAX. Abrir ENAd.pbip en Power BI Desktop y actualizar el modelo. Los datos actuales están incorporados en la partición M para que el proyecto sea portable; no contiene credenciales.

La extracción real encontró {extraction['rows']} eventos atribuibles a Flutter. Se excluyeron {extraction['excludedOtherOrUnknownPlatform']} registros de otra plataforma o sin origen verificable. Los porcentajes quedan vacíos cuando no existe denominador; no se inventan actividades ni agrupaciones. Los datos de las pruebas del emulador no forman parte del reporte.

La publicación web está bloqueada: el tenant universitario deshabilita la edición de modelos de datos en el servicio Power BI. La captura powerbi_tenant_block.png contiene el aviso. Este proyecto fue validado contra los esquemas JSON públicos de Microsoft, pero no pudo abrirse ni renderizarse en Power BI Desktop, que no está instalado en este equipo.

Recarga manual: ejecutar tools/export_metrics.cjs desde el repositorio Flutter; convertir flutter_bq_events.csv con tools/build_powerbi.py. Abrir el proyecto, actualizar, revisar los totales y publicar de forma privada en Mi área de trabajo cuando el tenant lo permita. No usar Publicar en la web.

BQ #4 cuenta actividades planeadas confirmadas, no actividades impartidas. BQ #11 utiliza título y materia; participación calcula la frecuencia sobre el total del periodo. BQ #14 cuenta decisiones de agrupación observadas y muestra materia/tamaño/muestra; no atribuye eficacia a un método. Los eventos históricos groupingEvents sin plataforma se excluyen.

Referencias: https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-report y https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-dataset
'''
(PACKAGE/'README.md').write_text(readme,encoding='utf-8')
shutil.copyfile(OUT/'flutter_bq_events.csv',PACKAGE/'flutter_bq_events.csv')
shutil.copyfile(OUT/'metrics_cutoff.json',PACKAGE/'metrics_cutoff.json')
shutil.make_archive(str(OUT/'ENAd_Flutter_PowerBI'),'zip',PACKAGE)
print('Prepared three-page Power BI project with actual extraction and empty-state measures')
