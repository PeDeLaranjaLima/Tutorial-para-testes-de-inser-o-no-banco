SHOW data_directory;

WITH xml_src AS (
    SELECT xmlparse(document pg_read_file('OH2_ONS_SEPPMU_120fps.xml')) AS xml_data
)

SELECT pg_read_file('OH2_ONS_SEPPMU_120fps.xml');

SELECT array_length(
    xpath(
        '//s:evento',
        xmlparse(document pg_read_file('OH2_ONS_SEPPMU_120fps.xml')),
        ARRAY[ARRAY['s','smsf2']]
    ),
    1
);

SELECT
(xpath('//s:pmu/s:idName/text()', xml_data, ARRAY[ARRAY['s','smsf2']]))[1]::text AS id_name,
(xpath('//s:pmu/s:voltLevel/text()', xml_data, ARRAY[ARRAY['s','smsf2']]))[1]::text AS volt_level
FROM (
  SELECT xmlparse(document pg_read_file('OH2_ONS_SEPPMU_120fps.xml')) AS xml_data
) t;

SELECT
(xpath('s:pName/text()', ph, ARRAY[ARRAY['s','smsf2']]))[1]::text AS nome,
(xpath('s:pPhase/text()', ph, ARRAY[ARRAY['s','smsf2']]))[1]::text AS fase,
(xpath('s:modId/text()', ph, ARRAY[ARRAY['s','smsf2']]))[1]::text AS mod_id
FROM (
   SELECT unnest(
       xpath(
         '//s:phasor',
         xmlparse(document pg_read_file('OH2_ONS_SEPPMU_120fps.xml')),
         ARRAY[ARRAY['s','smsf2']]
       )
   ) AS ph
) t;

SELECT
(xpath('//s:local/s:area/text()', x, ARRAY[ARRAY['s','smsf2']]))[1]::text AS area,
(xpath('//s:local/s:state/text()', x, ARRAY[ARRAY['s','smsf2']]))[1]::text AS state,
(xpath('//s:local/s:station/text()', x, ARRAY[ARRAY['s','smsf2']]))[1]::text AS station
FROM (
   SELECT xmlparse(document pg_read_file('OH2_ONS_SEPPMU_120fps.xml')) x
) t;


-- ==========================================
-- CARGA INICIAL - SMSF
-- ==========================================

-- ------------------------------------------
-- 1. AREA
-- ------------------------------------------

INSERT INTO area (nm_area, acr_area)
VALUES
('Norte','N'),
('Nordeste','NE'),
('Centro-Oeste','CO'),
('Sudeste','SE'),
('Sul','S')
ON CONFLICT (nm_area, acr_area) DO NOTHING;

-- ------------------------------------------
-- 2. UNIDADE FEDERATIVA
-- ------------------------------------------

INSERT INTO unidade_federativa (nm_unidade_federativa, acr_unidade_federativa, id_area)
VALUES
(
    'São Paulo',
    'SP',
    (SELECT id_area FROM area WHERE nm_area = 'Sudeste')
),
(
    'Bahia',
    'BA',
    (SELECT id_area FROM area WHERE nm_area = 'Nordeste')
)
ON CONFLICT (nm_unidade_federativa, acr_unidade_federativa) DO NOTHING;

-- ------------------------------------------
-- 3. LOCALIZACAO
-- ------------------------------------------

INSERT INTO localizacao (latitude, longitude, id_unidade_federativa)
VALUES
(
    -23.5505,
    -46.6333,
    (SELECT id_unidade_federativa FROM unidade_federativa WHERE acr_unidade_federativa = 'SP')
),
(
    -12.9714,
    -38.5014,
    (SELECT id_unidade_federativa FROM unidade_federativa WHERE acr_unidade_federativa = 'BA')
);

-- ------------------------------------------
-- 4. TERMINAL
-- ------------------------------------------

INSERT INTO terminal (tensao_base, nm_terminal, id_localizacao)
VALUES
(
    138.0,
    'Terminal SP 1',
    (SELECT id_localizacao FROM localizacao WHERE latitude = -23.5505 LIMIT 1)
),
(
    230.0,
    'Terminal BA 1',
    (SELECT id_localizacao FROM localizacao WHERE latitude = -12.9714 LIMIT 1)
);

-- ------------------------------------------
-- 5. EVENTO
-- ------------------------------------------

INSERT INTO evento (tipo_gatilho, id_evento_validado, id_terminal)
VALUES
(
    'TIPO1',
    NULL,
    (SELECT id_terminal FROM terminal WHERE nm_terminal = 'Terminal SP 1')
),
(
    'TIPO2',
    NULL,
    (SELECT id_terminal FROM terminal WHERE nm_terminal = 'Terminal BA 1')
),
(
    'TIPO1',
    1,
    (SELECT id_terminal FROM terminal WHERE nm_terminal = 'Terminal SP 1')
),
(
    'TIPO2',
    2,
    (SELECT id_terminal FROM terminal WHERE nm_terminal = 'Terminal BA 1')
),
(
    'TIPO1',
    NULL,
    (SELECT id_terminal FROM terminal WHERE nm_terminal = 'Terminal SP 1')
);

-- ------------------------------------------
-- 6. EVENTO_SP
-- ------------------------------------------

INSERT INTO evento_sp (soc_inicial, soc_final, taxa, total_frames_faltantes, id_evento)
VALUES
(20,80,1,0,1),
(30,75,2,2,2),
(10,60,1,1,3),
(50,90,2,0,4),
(40,85,1,3,5);

-- ------------------------------------------
-- 7. EVENTO_OG
-- ------------------------------------------

INSERT INTO evento_og (id_evento_og, link_og, id_evento)
VALUES
(1,'http://servidor/og/evento1.mp4',1),
(2,'http://servidor/og/evento2.mp4',2),
(3,'http://servidor/og/evento3.mp4',3),
(4,'http://servidor/og/evento4.mp4',4),
(5,'http://servidor/og/evento5.mp4',5);

-- ------------------------------------------
-- 8. EVENTO_CF
-- ------------------------------------------

INSERT INTO evento_cf (id_evento)
VALUES
(1),
(2),
(3),
(4),
(5);