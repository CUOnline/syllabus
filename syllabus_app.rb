require 'bundler/setup'
require 'wolf_core'
require 'wolf_core/auth'
require './syllabus_worker'

class SyllabusApp < WolfCore::App
  set :root, File.dirname(__FILE__)
  self.setup

  set :title, 'Syllabus Exporter'

  get '/' do
    slim :index
  end

  get '/view/:id' do
    course = canvas_api(:get, "courses/#{params['id']}?include[]=syllabus_body")

    if course['syllabus_body'].nil? || course['syllabus_body'].empty?
      return 'Syllabus missing or empty'
    end

    course['syllabus_body']
  end

  post '/' do
    query_string = %{
      SELECT distinct id, name, code
      FROM course_dim
      WHERE code LIKE ?
        AND name LIKE ?
        AND workflow_state != 'deleted'
        AND enrollment_term_id = ?; }

    @results = canvas_data(query_string,
                          "%#{params['department']}%",
                          "%#{params['search-term']}%",
                          shard_id(params['enrollment-term']))

    slim :results
  end


  post '/export' do
    Resque.enqueue(SyllabusWorker, {
      'export_ids' => params['export_ids'],
      'user_email' => session['user_email']
    })
    redirect to('/')
  end

  # No separate department entities in Canvas, just hardcode them
  set :departments, [
    'AAS' ,'ACCT','AGRI','ANAT','ANEQ','ANES','ANMS','ANTH','ANTP','ARAB',
    'ARCH','ARTH','ARTS','BANA','BIOE','BIOL','BIOS','BLAW','BMIN','BUSN',
    'CANB','CAND','CBHS','CCDI','CCDM','CHBH','CHEM','CHIN','CLDE','CLSC',
    'CMDT','CNCR','COMM','CPBS','CPCE','CRJU','CSCI','CSDV','CVEN','DERM',
    'DISP','DPER','DPTR','DSAD','DSBS','DSEL','DSEN','DSEP','DSFD','DSGD',
    'DSOD','DSON','DSOP','DSOR','DSOS','DSOT','DSPD','DSPE','DSPL','DSRE',
    'DSRP','DSSD','ECED','ECON','EDFN','EDHD','EDLI','EDRM','EDUC','EHOH',
    'ELEC','ELED','EMED','ENGL','ENGR','ENTP','ENVS','EPID','EPSY','ERHS',
    'ETHS','ETST','FILM','FINE','FITV','FMMD','FNCE','FREN','FSHN','GEMM',
    'GENC','GEOG','GEOL','GERO','GRMN','HBSC','HDFR','HDFS','HESC','HIPR',
    'HIS' ,'HIST','HLTH','HMGP','HPL' ,'HSMP','HUMN','IDPT','IEOO','IMMU',
    'INTB','INTE','INTS','IPED','IPHY','ISMG','ITED','IWKS','JTCM','LATN',
    'LCRT','LDAR','MATH','MCKE','MECH','MEDS','MGMT','MICB','MILR','MINS',
    'MIPO','MKTG','MLNG','MOLB','MPAS','MSRA','MTAX','MTED','MTH' ,'MU'  ,
    'MUSC','NCBE','NCCM','NCED','NCEG','NCES','NCMA','NEUR','NRSC','NSUR',
    'NUDO','NURS','OBGY','OPHT','ORTH','OTOL','PATH','PBHC','PBHL','PEDS',
    'PHCL','PHIL','PHLY','PHMD','PHRD','PHSC','PHYS','PMUS','PRDI','PRDO',
    'PRMD','PSCI','PSCY','PSYC','PSYM','PUAD','PUBH','RADI','RAON','RHSC',
    'RISK','RLST','RPSC','RSEM','SCHL','SECE','SJUS','SOCO','SOCY','SPAN',
    'SPCM','SPED','SPSY','SRMS','SSCI','STBB','STDY','SURG','SUST','TCED',
    'THTR','TLED','TXCL','UEDU','UNHL','URBN','URPL','VSCS','WGST','XBUS',
    'XHAD' ]
end
