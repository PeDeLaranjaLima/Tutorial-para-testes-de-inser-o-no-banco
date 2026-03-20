-- 1. Criar tabelas que não possuem chaves estrangeiras primeiro (ou criar os tipos)

CREATE TABLE area 
( 
 id_area SERIAL PRIMARY KEY,  
 nm_area VARCHAR NOT NULL,  
 acr_area VARCHAR,  
 UNIQUE (nm_area, acr_area)
); 

CREATE TABLE unidade_federativa 
( 
 id_unidade_federativa SERIAL PRIMARY KEY,  
 nm_unidade_federativa VARCHAR NOT NULL, -- Alterado de INT para VARCHAR  
 acr_unidade_federativa VARCHAR NOT NULL,  
 id_area INT,  
 UNIQUE (nm_unidade_federativa, acr_unidade_federativa)
); 

CREATE TABLE localizacao 
( 
 id_localizacao SERIAL PRIMARY KEY,  
 latitude FLOAT NOT NULL,  
 longitude FLOAT NOT NULL,  
 id_unidade_federativa INT  
); 

CREATE TABLE terminal 
( 
 id_terminal SERIAL PRIMARY KEY,  
 tensao_base FLOAT NOT NULL,  
 nm_terminal VARCHAR NOT NULL,  
 id_localizacao INT  
); 

CREATE TABLE evento 
( 
 id_evento SERIAL PRIMARY KEY,  
 tipo_gatilho VARCHAR NOT NULL CHECK (tipo_gatilho IN ('TIPO1', 'TIPO2')), -- Simulação de ENUM
 id_evento_validado INT,  
 id_terminal INT  
); 

CREATE TABLE evento_sp 
( 
 id_evento_sp SERIAL PRIMARY KEY,  
 soc_inicial INT,  
 soc_final INT,  
 taxa INT,  
 total_frames_faltantes INT,  
 id_evento INT  
); 

CREATE TABLE evento_og 
( 
 id_evento_og INT PRIMARY KEY,  
 link_og VARCHAR,  
 id_evento INT  
); 

CREATE TABLE evento_cf 
( 
 id_evento_cf SERIAL PRIMARY KEY,  
 id_evento INT  
); 

CREATE TABLE Entidade1 
( 
 "Chave da Entidade 1" SERIAL PRIMARY KEY,  
 "Atributo 1 da Entidade 1" INT,  
 "Atributo n da Entidade 1" INT  
); 

CREATE TABLE Entidade2 
( 
 "Chave da Entidade 2" SERIAL PRIMARY KEY,  
 "Atributo n da Entidade 2" INT,  
 "Atributo 1 da Entidade 2" INT,  
 idEntidade1 INT  
); 

---
--- Restrições de Chave Estrangeira
---

ALTER TABLE terminal ADD FOREIGN KEY(id_localizacao) REFERENCES localizacao (id_localizacao);
ALTER TABLE localizacao ADD FOREIGN KEY(id_unidade_federativa) REFERENCES unidade_federativa (id_unidade_federativa);
ALTER TABLE unidade_federativa ADD FOREIGN KEY(id_area) REFERENCES area (id_area);
ALTER TABLE evento_sp ADD FOREIGN KEY(id_evento) REFERENCES evento (id_evento);
ALTER TABLE evento_og ADD FOREIGN KEY(id_evento) REFERENCES evento (id_evento);
ALTER TABLE evento ADD FOREIGN KEY(id_terminal) REFERENCES terminal (id_terminal);
ALTER TABLE Entidade2 ADD FOREIGN KEY(idEntidade1) REFERENCES Entidade1 ("Chave da Entidade 1");
ALTER TABLE evento_cf ADD FOREIGN KEY(id_evento) REFERENCES evento (id_evento);