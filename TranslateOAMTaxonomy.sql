-- Sector Translations
UPDATE classification SET name='Educacion y cultura', iati_name='Educacion y cultura'
 WHERE classification_id = (select classification_id from classification where name = 'Education policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Abastecimiento de agua y saneamiento - sistemas grandes', iati_name='Abastecimiento de agua y saneamiento - sistemas grandes'
 WHERE classification_id = (select classification_id from classification where name = 'Water supply and sanitation - large systems' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Formación y servicios de educación', iati_name='Formación y servicios de educación'
 WHERE classification_id = (select classification_id from classification where name = 'Education facilities and training' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política de población y gestión administrativa', iati_name='Política de población y gestión administrativa'
 WHERE classification_id = (select classification_id from classification where name = 'Population policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Múltiples sector educación/formación', iati_name='Múltiples sector educación/formación'
 WHERE classification_id = (select classification_id from classification where name = 'Multisector education/training' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Administración del gobierno', iati_name='Administración del gobierno'
 WHERE classification_id = (select classification_id from classification where name = 'Government administration' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Desarrollo agrícola', iati_name='Desarrollo agrícola'
 WHERE classification_id = (select classification_id from classification where name = 'Agricultural development' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Transmisión eléctrica/distribución', iati_name='Transmisión eléctrica/distribución'
 WHERE classification_id = (select classification_id from classification where name = 'Electrical transmission/ distribution' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Recursos de tierras agrícolas', iati_name='Recursos de tierras agrícolas'
 WHERE classification_id = (select classification_id from classification where name = 'Agricultural land resources' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Investigación educativa', iati_name='Investigación educativa'
 WHERE classification_id = (select classification_id from classification where name = 'Educational research' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Servicios y asistencia de socorro material', iati_name='Servicios y asistencia de socorro material'
 WHERE classification_id = (select classification_id from classification where name = 'Material relief assistance and services' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Derechos humanos', iati_name='Derechos humanos'
 WHERE classification_id = (select classification_id from classification where name = 'Human rights' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Desarrollo urbano y gestión', iati_name='Desarrollo urbano y gestión'
 WHERE classification_id = (select classification_id from classification where name = 'Urban development and management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Servicios sociales o de bienestar', iati_name='Servicios sociales o de bienestar'
 WHERE classification_id = (select classification_id from classification where name = 'Social/ welfare services' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política en materia de recursos hídricos y gestión administrativa', iati_name='Política en materia de recursos hídricos y gestión administrativa'
 WHERE classification_id = (select classification_id from classification where name = 'Water resources policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Múltiples ayudas sector de los servicios sociales básicos', iati_name='Múltiples ayudas sector de los servicios sociales básicos'
 WHERE classification_id = (select classification_id from classification where name = 'Multisector aid for basic social services' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Gestión de residuos/eliminación', iati_name='Gestión de residuos/eliminación'
 WHERE classification_id = (select classification_id from classification where name = 'Waste management/disposal' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Desarrollo del río', iati_name='Desarrollo del río'
 WHERE classification_id = (select classification_id from classification where name = 'River development' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Sector formal intermediarios financieros', iati_name='Sector formal intermediarios financieros'
 WHERE classification_id = (select classification_id from classification where name = 'Formal sector financial intermediaries' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Transporte por carretera', iati_name='Transporte por carretera'
 WHERE classification_id = (select classification_id from classification where name = 'Road transport' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Múltiples ayudas sector', iati_name='Múltiples ayudas sector'
 WHERE classification_id = (select classification_id from classification where name = 'Multisector aid' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Educación agrícola o formación', iati_name='Educación agrícola o formación' 
 WHERE classification_id = (select classification_id from classification where name = 'Agricultural education/training' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política Agraria y gestión administrativa', iati_name='Política Agraria y gestión administrativa' 
 WHERE classification_id = (select classification_id from classification where name = 'Agricultural policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Investigación agrícola', iati_name='Investigación agrícola' 
 WHERE classification_id = (select classification_id from classification where name = 'Agricultural research' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Servicios agrícolas', iati_name='Servicios agrícolas' 
 WHERE classification_id = (select classification_id from classification where name = 'Agricultural services' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Recursos hídricos agrícolas', iati_name='Recursos hídricos agrícolas' 
 WHERE classification_id = (select classification_id from classification where name = 'Agricultural water resources' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Industrias agrícolas', iati_name='Industrias agrícolas' 
 WHERE classification_id = (select classification_id from classification where name = 'Agro-industries' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Transporte aéreo', iati_name='Transporte aéreo' 
 WHERE classification_id = (select classification_id from classification where name = 'Air transport' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Básicos de agua potable y saneamiento básico', iati_name='Básicos de agua potable y saneamiento básico' 
 WHERE classification_id = (select classification_id from classification where name = 'Basic drinking water supply and basic sanitation' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Habilidades básicas de la vida para jóvenes y adultos', iati_name='Habilidades básicas de la vida para jóvenes y adultos' 
 WHERE classification_id = (select classification_id from classification where name = 'Basic life skills for youth and adults' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Diversidad biológica', iati_name='Diversidad biológica' 
 WHERE classification_id = (select classification_id from classification where name = 'Bio-diversity' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política de comunicación y gestión administrativa', iati_name='Política de comunicación y gestión administrativa' 
 WHERE classification_id = (select classification_id from classification where name = 'Communications policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Cultura y recreación', iati_name='Cultura y recreación' 
 WHERE classification_id = (select classification_id from classification where name = 'Culture and recreation' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política económica y de desarrollo o planificación', iati_name='Política económica y de desarrollo o planificación' 
 WHERE classification_id = (select classification_id from classification where name = 'Economic and development policy/planning' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política energética y gestión administrativa', iati_name='Política energética y gestión administrativa' 
 WHERE classification_id = (select classification_id from classification where name = 'Energy policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política ambiental y gestión administrativa', iati_name='Política ambiental y gestión administrativa' 
 WHERE classification_id = (select classification_id from classification where name = 'Environmental policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Desarrollo de la pesca', iati_name='Desarrollo de la pesca' 
 WHERE classification_id = (select classification_id from classification where name = 'Fishery development' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Prevención de inundaciones o control', iati_name='Prevención de inundaciones o control'
 WHERE classification_id = (select classification_id from classification where name = 'Flood prevention/control' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Desarrollo forestal', iati_name='Desarrollo forestal'
 WHERE classification_id = (select classification_id from classification where name = 'Forestry development' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Educación para la salud', iati_name='Educación para la salud'
 WHERE classification_id = (select classification_id from classification where name = 'Health education' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='La política de salud y gestión administrativa', iati_name='La política de salud y gestión administrativa' 
 WHERE classification_id = (select classification_id from classification where name = 'Health policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Educación superior', iati_name='Educación superior' 
 WHERE classification_id = (select classification_id from classification where name = 'Higher education' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política de vivienda y gestión administrativa', iati_name='Política de vivienda y gestión administrativa' 
 WHERE classification_id = (select classification_id from classification where name = 'Housing policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Control de enfermedades infecciosas', iati_name='Control de enfermedades infecciosas' 
 WHERE classification_id = (select classification_id from classification where name = 'Infectious disease control' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Desarrollo legal y judicial', iati_name='Desarrollo legal y judicial' 
 WHERE classification_id = (select classification_id from classification where name = 'Legal and judicial development' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Ganado', iati_name='Ganado' 
 WHERE classification_id = (select classification_id from classification where name = 'Livestock' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Ganado o servicios veterinarios', iati_name='Ganado o servicios veterinarios' 
 WHERE classification_id = (select classification_id from classification where name = 'Livestock/veterinary services' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Mineral o la política minera y gestión administrativa', iati_name='Mineral o la política minera y gestión administrativa' 
 WHERE classification_id = (select classification_id from classification where name = 'Mineral/mining policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Educación primaria', iati_name='Educación primaria' 
 WHERE classification_id = (select classification_id from classification where name = 'Primary education' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Asistencia médica reproductiva', iati_name='Asistencia médica reproductiva' 
 WHERE classification_id = (select classification_id from classification where name = 'Reproductive health care' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Sectores no especificados', iati_name='Sectores no especificados' 
 WHERE classification_id = (select classification_id from classification where name = 'Sectors not specified' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Formación del profesorado', iati_name='Formación del profesorado' 
 WHERE classification_id = (select classification_id from classification where name = 'Teacher training' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Telecomunicaciones', iati_name='Telecomunicaciones' 
 WHERE classification_id = (select classification_id from classification where name = 'Telecommunications' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política de turismo y gestión administrativa', iati_name='Política de turismo y gestión administrativa' 
 WHERE classification_id = (select classification_id from classification where name = 'Tourism policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Industria de equipos de transporte', iati_name='Industria de equipos de transporte' 
 WHERE classification_id = (select classification_id from classification where name = 'Transport equipment industry' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política de transportes y gestión administrativa', iati_name='Política de transportes y gestión administrativa' 
 WHERE classification_id = (select classification_id from classification where name = 'Transport policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Formación profesional', iati_name='Formación profesional' 
 WHERE classification_id = (select classification_id from classification where name = 'Vocational training' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Transporte por agua', iati_name='Transporte por agua' 
 WHERE classification_id = (select classification_id from classification where name = 'Water transport' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Gastos administrativos', iati_name='Gastos administrativos' 
 WHERE classification_id = (select classification_id from classification where name = 'Administrative costs' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Servicios financieros agrícolas', iati_name='Servicios financieros agrícolas'
 WHERE classification_id = (select classification_id from classification where name = 'Agricultural financial services' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Insumos agrícolas', iati_name='Insumos agrícolas'
 WHERE classification_id = (select classification_id from classification where name = 'Agricultural inputs' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Asistencia sanitaria básica', iati_name='Asistencia sanitaria básica'
 WHERE classification_id = (select classification_id from classification where name = 'Basic health care' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Infraestructura de la salud básica', iati_name='Infraestructura de la salud básica'
 WHERE classification_id = (select classification_id from classification where name = 'Basic health infrastructure' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Nutrición básica', iati_name='Nutrición básica'
 WHERE classification_id = (select classification_id from classification where name = 'Basic nutrition' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Las instituciones y servicios de apoyo empresarial', iati_name='Las instituciones y servicios de apoyo empresarial'
 WHERE classification_id = (select classification_id from classification where name = 'Business support services and institutions' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Construcción política y gestión administrativa', iati_name='Construcción política y gestión administrativa'
 WHERE classification_id = (select classification_id from classification where name = 'Construction policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Preparación y prevención de desastres', iati_name='Preparación y prevención de desastres'
 WHERE classification_id = (select classification_id from classification where name = 'Disaster prevention and preparedness' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Educación y formación en abastecimiento de agua y saneamiento', iati_name='Educación y formación en abastecimiento de agua y saneamiento'
 WHERE classification_id = (select classification_id from classification where name = 'Education and training in water supply and sanitation' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Ayuda alimentaria de emergencia', iati_name='Ayuda alimentaria de emergencia'
 WHERE classification_id = (select classification_id from classification where name = 'Emergency food aid' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Investigación ambiental', iati_name='Investigación ambiental'
 WHERE classification_id = (select classification_id from classification where name = 'Environmental research' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Planificación familiar', iati_name='Planificación familiar'
 WHERE classification_id = (select classification_id from classification where name = 'Family planning' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política financiera y gestión administrativa', iati_name='Política financiera y gestión administrativa'
 WHERE classification_id = (select classification_id from classification where name = 'Financial policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política pesquera y gestión administrativa', iati_name='Política pesquera y gestión administrativa'
 WHERE classification_id = (select classification_id from classification where name = 'Fishing policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Ayuda alimentaria/Programas de seguridad alimentaria', iati_name='Ayuda alimentaria/Programas de seguridad alimentaria'
 WHERE classification_id = (select classification_id from classification where name = 'Food aid/Food security programmes' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Producción de cultivos alimentarios', iati_name='Producción de cultivos alimentarios'
 WHERE classification_id = (select classification_id from classification where name = 'Food crop production' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política forestal y gestión administrativa', iati_name='Política forestal y gestión administrativa'
 WHERE classification_id = (select classification_id from classification where name = 'Forestry policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Apoyo de presupuesto', iati_name='Apoyo de presupuesto' WHERE classification_id = (select classification_id from classification where name = 'General budget support' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Desarrollo del personal de la salud', iati_name='Desarrollo del personal de la salud'
 WHERE classification_id = (select classification_id from classification where name = 'Health personnel development' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Las plantas hidroeléctrica', iati_name='Las plantas hidroeléctrica'
 WHERE classification_id = (select classification_id from classification where name = 'Hydro-electric power plants' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Desarrollo industrial', iati_name='Desarrollo industrial'
 WHERE classification_id = (select classification_id from classification where name = 'Industrial development' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política industrial y gestión administrativa', iati_name='Política industrial y gestión administrativa'
 WHERE classification_id = (select classification_id from classification where name = 'Industrial policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Intermediarios financieros informales o semiformales', iati_name='Intermediarios financieros informales o semiformales'
 WHERE classification_id = (select classification_id from classification where name = 'Informal/semi-formal financial intermediaries' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Tecnología de la información y comunicación', iati_name='Tecnología de la información y comunicación'
 WHERE classification_id = (select classification_id from classification where name = 'Information and communication technology (ICT)' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Control de la malaria', iati_name='Control de la malaria'
 WHERE classification_id = (select classification_id from classification where name = 'Malaria control' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Educación médica o de formación', iati_name='Educación médica o de formación'
 WHERE classification_id = (select classification_id from classification where name = 'Medical education/training' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Servicios médicos', iati_name='Servicios médicos'
 WHERE classification_id = (select classification_id from classification where name = 'Medical services' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Exploración y prospección de minerales', iati_name='Exploración y prospección de minerales'
 WHERE classification_id = (select classification_id from classification where name = 'Mineral prospection and exploration' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Instituciones monetarias', iati_name='Instituciones monetarias'
 WHERE classification_id = (select classification_id from classification where name = 'Monetary institutions' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Petróleo y gas', iati_name='Petróleo y gas'
 WHERE classification_id = (select classification_id from classification where name = 'Oil and gas' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Después de conflicto edificio de paz', iati_name='Después de conflicto edificio de paz'
 WHERE classification_id = (select classification_id from classification where name = 'Post-conflict peace-building (UN)' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Generación de energía o fuentes no renovables', iati_name='Generación de energía o fuentes no renovables'
 WHERE classification_id = (select classification_id from classification where name = 'Power generation/non-renewable sources' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Promoción de conciencia de desarrollo', iati_name='Promoción de conciencia de desarrollo'
 WHERE classification_id = (select classification_id from classification where name = 'Promotion of development awareness' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Gestión financiera del sector público', iati_name='Gestión financiera del sector público'
 WHERE classification_id = (select classification_id from classification where name = 'Public sector financial management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Radio o televisión o medios impresos', iati_name='Radio o televisión o medios impresos'
 WHERE classification_id = (select classification_id from classification where name = 'Radio/television/print media' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Transporte ferroviario', iati_name='Transporte ferroviario'
 WHERE classification_id = (select classification_id from classification where name = 'Rail transport' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Rehabilitación y reconstrucción alivio', iati_name='Rehabilitación y reconstrucción alivio'
 WHERE classification_id = (select classification_id from classification where name = 'Reconstruction relief and rehabilitation' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Reintegración y control de SALW', iati_name='Reintegración y control de SALW'
 WHERE classification_id = (select classification_id from classification where name = 'Reintegration and SALW control' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Investigación o instituciones científicas', iati_name='Investigación o instituciones científicas'
 WHERE classification_id = (select classification_id from classification where name = 'Research/scientific institutions' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Desarrollo rural', iati_name='Desarrollo rural'
 WHERE classification_id = (select classification_id from classification where name = 'Rural development' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Educación secundaria', iati_name='Educación secundaria'
 WHERE classification_id = (select classification_id from classification where name = 'Secondary education' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Pequeño y mediano tamaño desarrollo empresarial', iati_name='Pequeño y mediano tamaño desarrollo empresarial'
 WHERE classification_id = (select classification_id from classification where name = 'Small and medium-sized enterprises (SME) development' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Energía solar', iati_name='Energía solar'
 WHERE classification_id = (select classification_id from classification where name = 'Solar energy' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Control de las ETS incluyendo el VIH/SIDA', iati_name='Control de las ETS incluyendo el VIH/SIDA'
 WHERE classification_id = (select classification_id from classification where name = 'STD control including HIV/AIDS' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Fortalecimiento de la sociedad civil', iati_name='Fortalecimiento de la sociedad civil'
 WHERE classification_id = (select classification_id from classification where name = 'Strengthening civil society' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Apoyo a OGN internacional', iati_name='Apoyo a OGN internacional'
 WHERE classification_id = (select classification_id from classification where name = 'Support to international NGOs' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Facilitación del comercio', iati_name='Facilitación del comercio' 
 WHERE classification_id = (select classification_id from classification where name = 'Trade facilitation' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Política comercial y gestión administrativa', iati_name='Política comercial y gestión administrativa'
 WHERE classification_id = (select classification_id from classification where name = 'Trade policy and administrative management' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Protección de recursos hídricos', iati_name='Protección de recursos hídricos'
 WHERE classification_id = (select classification_id from classification where name = 'Water resources protection' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));
UPDATE classification SET name='Energía eólica', iati_name='Energía eólica'
 WHERE classification_id = (select classification_id from classification where name = 'Wind power' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Sector'));


-- Organization Type Translations
UPDATE classification SET name='Académico, formación e investigación', iati_name='Académico, formación e investigación'
 WHERE classification_id = (select classification_id from classification where name = 'Academic, Training and Research' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Organisation Type'));
UPDATE classification SET name='OGN internacional', iati_name='OGN internacional'
 WHERE classification_id = (select classification_id from classification where name = 'International NGO' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Organisation Type'));


-- Organization Role Translations
UPDATE classification SET name='Financiamiento', iati_name='Financiamiento'
 WHERE classification_id = (select classification_id from classification where name = 'Funding' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Organisation Role'));
UPDATE classification SET name='Implementar', iati_name='Implementar'
 WHERE classification_id = (select classification_id from classification where name = 'Implementing' and taxonomy_id = (SELECT taxonomy_id FROM taxonomy WHERE name = 'Organisation Role'));

