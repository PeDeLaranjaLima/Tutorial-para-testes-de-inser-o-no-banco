-- =============================================================================
-- 1. CRIAÇÃO DAS TABELAS -> Tive que ajustar o esquema
-- =============================================================================

CREATE TABLE area (
    id_area SERIAL PRIMARY KEY,
    nm_area VARCHAR NOT NULL,
    acr_area VARCHAR,
    UNIQUE (nm_area, acr_area)
);

CREATE TABLE unidade_federativa (
    id_unidade_federativa SERIAL PRIMARY KEY,
    nm_unidade_federativa VARCHAR NOT NULL,
    acr_unidade_federativa VARCHAR NOT NULL,
    id_area INT,
    UNIQUE (nm_unidade_federativa, acr_unidade_federativa)
);

CREATE TABLE localizacao (
    id_localizacao SERIAL PRIMARY KEY,
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    id_unidade_federativa INT
);

CREATE TABLE terminal (
    id_terminal SERIAL PRIMARY KEY,
    tensao_base FLOAT NOT NULL,
    nm_terminal VARCHAR NOT NULL,
    id_localizacao INT,
    -- Colunas adicionais para suportar os dados reais da planilha
    agente VARCHAR,
    codigo_estacao VARCHAR
);

CREATE TABLE evento (
    id_evento SERIAL PRIMARY KEY,
    tipo_gatilho VARCHAR NOT NULL CHECK (tipo_gatilho IN ('TIPO1', 'TIPO2')),
    id_evento_validado INT,
    id_terminal INT
);

CREATE TABLE evento_sp (
    id_evento_sp SERIAL PRIMARY KEY,
    soc_inicial INT,
    soc_final INT,
    taxa INT,
    total_frames_faltantes INT,
    id_evento INT
);

CREATE TABLE evento_og (
    id_evento_og SERIAL PRIMARY KEY,
    link_og VARCHAR,
    id_evento INT
);

CREATE TABLE evento_cf (
    id_evento_cf SERIAL PRIMARY KEY,
    id_evento INT
);

/*-- (As tabelas evento_sp, evento_og, evento_cf e Entidades permanecem iguais ao esquema da Erika)
CREATE TABLE evento_sp (id_evento_sp SERIAL PRIMARY KEY, soc_inicial INT, soc_final INT, taxa INT, total_frames_faltantes INT, id_evento INT);
CREATE TABLE evento_og (id_evento_og INT PRIMARY KEY, link_og VARCHAR, id_evento INT);
CREATE TABLE evento_cf (id_evento_cf SERIAL PRIMARY KEY, id_evento INT);*/

-- =============================================================================
-- 2. RESTRIÇÕES DE CHAVE ESTRANGEIRA
-- =============================================================================

ALTER TABLE unidade_federativa ADD FOREIGN KEY(id_area) REFERENCES area (id_area);
ALTER TABLE localizacao ADD FOREIGN KEY(id_unidade_federativa) REFERENCES unidade_federativa (id_unidade_federativa);
ALTER TABLE terminal ADD FOREIGN KEY(id_localizacao) REFERENCES localizacao (id_localizacao);
ALTER TABLE evento ADD FOREIGN KEY(id_terminal) REFERENCES terminal (id_terminal);
ALTER TABLE evento_sp ADD FOREIGN KEY(id_evento) REFERENCES evento (id_evento);
ALTER TABLE evento_og ADD FOREIGN KEY(id_evento) REFERENCES evento (id_evento);
ALTER TABLE evento_cf ADD FOREIGN KEY(id_evento) REFERENCES evento (id_evento);

-- =============================================================================
-- Carregar com dados reais (METADADOS.csv)
-- =============================================================================

-- Preparação da Staging -> armazenamento temporário
DROP TABLE IF EXISTS staging_metadados;
CREATE TEMP TABLE staging_metadados (
    agente TEXT, station_name TEXT, idname TEXT, idfluxo TEXT, 
    idcode TEXT, voltlevel TEXT, area TEXT, state TEXT, 
    station TEXT, lat TEXT, long TEXT
);

COPY staging_metadados FROM 'C:\Program Files\PostgreSQL\18\data\METADADOS.csv' 
WITH (FORMAT csv, HEADER true, DELIMITER E'\t', ENCODING 'UTF8');

-- Popular ÁREA
INSERT INTO area (nm_area, acr_area)
SELECT DISTINCT area, area 
FROM staging_metadados
WHERE area IS NOT NULL AND area <> ''
ON CONFLICT (nm_area, acr_area) DO NOTHING;

-- Popular UNIDADE FEDERATIVA
INSERT INTO unidade_federativa (acr_unidade_federativa, nm_unidade_federativa, id_area)
SELECT DISTINCT 
    s.state, 
    s.state, 
    a.id_area
FROM staging_metadados s
JOIN area a ON s.area = a.acr_area
WHERE s.state IS NOT NULL
ON CONFLICT DO NOTHING;

-- Popular LOCALIZACAO
INSERT INTO localizacao (latitude, longitude, id_unidade_federativa)
SELECT DISTINCT
    REPLACE(REGEXP_REPLACE(lat, '[^0-9,.-]', '', 'g'), ',', '.')::float, 
    REPLACE(REGEXP_REPLACE(long, '[^0-9,.-]', '', 'g'), ',', '.')::float,
    uf.id_unidade_federativa
FROM staging_metadados s
JOIN unidade_federativa uf ON s.state = uf.acr_unidade_federativa
WHERE lat IS NOT NULL AND lat <> ''
ON CONFLICT DO NOTHING;

-- Popular TERMINAL
INSERT INTO terminal (nm_terminal, tensao_base, agente, id_localizacao, codigo_estacao)
SELECT DISTINCT
    s.idname,
    (REGEXP_REPLACE(s.voltlevel, '[^0-9]', '', 'g')::numeric / 1000)::float,
    s.agente,
    l.id_localizacao,
    s.station_name
FROM staging_metadados s
JOIN unidade_federativa uf ON s.state = uf.acr_unidade_federativa
JOIN localizacao l ON l.id_unidade_federativa = uf.id_unidade_federativa 
    AND l.latitude = REPLACE(REGEXP_REPLACE(s.lat, '[^0-9,.-]', '', 'g'), ',', '.')::float
    AND l.longitude = REPLACE(REGEXP_REPLACE(s.long, '[^0-9,.-]', '', 'g'), ',', '.')::float;


-- =============================================================================
-- 4. IMPORTAR EVENTOS.csv
--    O CSV original tem DUAS linhas de cabecalho. Usamos o arquivo ja limpo
--    em /tmp/EVENTOS_clean.csv (geramos com tail -n +3).
-- =============================================================================

DROP TABLE IF EXISTS staging_eventos;
CREATE TEMP TABLE staging_eventos (
    idx TEXT,
    data_evento TEXT,
    agente TEXT,
    inicio_utc TEXT,
    inicio_bsb TEXT,
    tr_ms TEXT,
    variacao_defasagem TEXT,
    link_sincro TEXT,
    link_oscilo TEXT
);

COPY staging_eventos
FROM 'C:\Program Files\PostgreSQL\18\data\EVENTOS.csv'
WITH (
    FORMAT csv,
    DELIMITER ',',
    QUOTE '''',
    ENCODING 'UTF8'
);

-- Popular EVENTO, EVENTO_OG e EVENTO_CF preservando a correspondencia
-- linha-a-linha com a staging (o INSERT ... SELECT JOIN original gerava
-- explosao cartesiana porque todos os eventos do mesmo agente compartilham
-- id_terminal e, portanto, o JOIN agente->terminal->evento retorna N*N).
DO $$
DECLARE
    r RECORD;
    v_id_terminal INT;
    v_id_evento INT;
BEGIN
    FOR r IN
        SELECT * FROM staging_eventos
        WHERE agente IS NOT NULL AND agente <> '' AND idx <> '#'
        ORDER BY NULLIF(idx, '')::int
    LOOP
        SELECT id_terminal INTO v_id_terminal
        FROM terminal WHERE agente = r.agente LIMIT 1;

        INSERT INTO evento (tipo_gatilho, id_terminal)
        VALUES ('TIPO1', v_id_terminal)
        RETURNING id_evento INTO v_id_evento;

        IF r.link_oscilo IS NOT NULL AND r.link_oscilo <> '' THEN
            INSERT INTO evento_og (link_og, id_evento)
            VALUES (r.link_oscilo, v_id_evento);
        END IF;

        INSERT INTO evento_cf (id_evento) VALUES (v_id_evento);
    END LOOP;
END $$;
