-- Código para população do banco dados artificiais, com a finalidade de disponibilizar insumos para o frontend

-- Limpar valores que podem ter sido inseridos na criação das tabelas anteriores
TRUNCATE TABLE evento_cf, evento_og, evento_sp, evento RESTART IDENTITY CASCADE;

-- ==========================================
-- CARREGAMENTO INICIAL
-- ==========================================

-- ------------------------------------------
-- 1. EVENTO (50 eventos aleatórios)
-- ------------------------------------------

INSERT INTO evento (tipo_gatilho, id_evento_validado, id_terminal)
SELECT
    CASE WHEN i % 2 = 0 THEN 'TIPO1' ELSE 'TIPO2' END,
    CASE WHEN i > 2 THEN i - 2 ELSE NULL END,
    CASE 
        WHEN i % 2 = 0 THEN (SELECT id_terminal FROM terminal WHERE nm_terminal = 'Terminal SP 1')
        ELSE (SELECT id_terminal FROM terminal WHERE nm_terminal = 'Terminal BA 1')
    END
FROM generate_series(1,50) AS i;

-- ------------------------------------------
-- 2. EVENTO_SP (50 eventos aleatórios)
-- ------------------------------------------

INSERT INTO evento_sp (soc_inicial, soc_final, taxa, total_frames_faltantes, id_evento)
SELECT
    (random()*50)::int,                 -- soc_inicial
    (random()*100)::int,                -- soc_final
    (1 + random()*2)::int,              -- taxa
    (random()*5)::int,                  -- frames faltantes
    id_evento
FROM evento
ORDER BY id_evento
LIMIT 50;

-- ------------------------------------------
-- 3. EVENTO_OG (50 eventos aleatórios)
-- ------------------------------------------

INSERT INTO evento_og (id_evento_og, link_og, id_evento)
SELECT
    id_evento,
    'http://servidor/og/evento' || id_evento || '.mp4',   -- link gerado somente para preenchimento, buscar alternativas futuramente
    id_evento
FROM evento
ORDER BY id_evento
LIMIT 50;

-- ------------------------------------------
-- 4. EVENTO_CF (50 eventos aleatórios)
-- ------------------------------------------

INSERT INTO evento_cf (id_evento)
SELECT id_evento
FROM evento
ORDER BY id_evento
LIMIT 50;

-- ------------------------------------------
-- 5. UNIDADE FEDERATIVA (50 localizações aleatórias)
-- ------------------------------------------

INSERT INTO unidade_federativa (nm_unidade_federativa, acr_unidade_federativa, id_area)
SELECT
    'Estado ' || i,
    'E' || i,
    (SELECT id_area FROM area ORDER BY id_area LIMIT 1 OFFSET (i % 5))
FROM generate_series(1,50) AS i;

-- ------------------------------------------
-- 6. LOCALIZACAO (50 localizações aleatórias)
-- ------------------------------------------

INSERT INTO localizacao (latitude, longitude, id_unidade_federativa)
SELECT
    -30 + random()*20,   -- latitude simulada
    -60 + random()*20,   -- longitude simulada
    id_unidade_federativa
FROM unidade_federativa
ORDER BY id_unidade_federativa
LIMIT 50;

-- ------------------------------------------
-- 7. TERMINAL (50 terminais aleatórios)
-- ------------------------------------------

INSERT INTO terminal (tensao_base, nm_terminal, id_localizacao)
SELECT
    (100 + random()*300)::int,  -- tensão entre 100 e 400
    'Terminal ' || id_localizacao,
    id_localizacao
FROM localizacao
ORDER BY id_localizacao
LIMIT 50;