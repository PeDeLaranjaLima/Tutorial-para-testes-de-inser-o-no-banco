## Tutorial para testes do banco de dados usando o localhost

# Passo 1 (Instalação do PostgreSQL):
Instalar o postgrasql, pode ser via link: https://www.postgresql.org/download/
Após a instalação e abertura do postgras, rodar o comando
`services.msc` no cmd windows* ou `sudo service postgresql start` no terminal ubuntu.

*Ele serve para verificar se o servidor está ativo, em caso afirmativo, siga para o *Passo 2*, se não, clique com botão direito → Start (Iniciar).

# Passo 2 (Instalação do pgAdmin):

Instalar o pgAdmin, usando o link: https://www.pgadmin.org/download/
Após a instalação, aba o programa, e se necessário use a senha do PostgreSQL. Na esquerda aparecerá o painel Servers.

# Passo 3 (Criação do primerio banco):
Clique na seta ao lado de Servers, e clique em PostgreSQL (localhost) - importante destacar que o servidor é nomeado de "PostgreSQL" + "número".
Ao clicar aparecerão algumas opções padrão, basta clicar com botão direito em Databases -> Create -> Database. Colocar um nome para o banco e salvar.

*Abaixo o passo a passo para execução dos códigos do repositório:*

# Passo 4 (Editor de código):

Clique no banco de dados que quer usar, clique em Tools -> Query Tool, assim irá aparecer o editor de código sql.
Após isso, é possível testar os códigos disponíveis no repositório da seguinte forma: Clique no ícone Open File -> Selecione seu arquivo .sql* -> Clique em Execute (F5)

*O arquivo a ser selecionado primeiro é nomeado "Criacao_tabelas_MIF".

# Passo 5 (Verificando se funcionou)

Mensagem "Query returned successfully", as tabelas aparecerão em:
Databases
 └ seu_banco
     └ Schemas
         └ public
             └ Tables
Clique com botão direito na tabela → View/Edit Data → All Rows.

Por fim, basta abrir novamente o Query Tool como explicado acima e repetir o *Passo 4* para o código "Insercao_artificial_MIF".


