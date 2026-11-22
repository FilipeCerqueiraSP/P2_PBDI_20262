# Prova - Data Warehouse na Nuvem com AWS

## Integrantes

- Filipe Henrique Silva Cerqueira - RA 2041382521022
- Thais Mauro Franco – RA 2041382521032
- Wilian Aparecido Domingos – RA 204138252118

## Ambiente AWS
- Integrante dono da conta: Filipe Henrique Silva Cerqueira
- RA usado nos nomes dos recursos: 204138252100
- ID da conta AWS: 339713019868
- Região: us-east-1

##FASE 1 - ENUNCIADO 2
## Dataset

(a): 9.800 linhas de dados, 18 colunas.

(b): ambas as datas usam DD/MM/AAAA. Pois tem datas como essa na linha 15: 22/11/2016, onde o 22 só pode ser dia, não mês.

(c): 11 linhas não tem código postal.

(d): Eldon Expressions Wood and Plastic Desk Accessories, Cherry Wood.
Que é "product name" da "row 6";
A vírgula não separa as colunas por que o nome está entre aspas, assim a virgula faz parte do nome.

## FASE 2
## ENUNCIADO 4 : 
- A regra 1: A regra 1 deixa o psql do CloudShell entrar pela internet, na porta 5432, sem ela a instância não teria acesso público.
- A regra 2: O grupo autoriza a si mesmo, o que permite que recursos de dentro do próprio grupo, como a placa de rede criada pelo job,
 conversem entre si. Sem essa regra o grupo não consegue acessar os próprios recursos.

 
## FASE 3
## ENUNCIADO 6 :
- O endpoint de gateway é só mais uma rota na tabela de rotas, permite acessar sem custo por hora.
- O endpoint de interface é uma placa de rede com IPs privados para usar de credencial nos serviços AWS, não usa gateway
por que o endpoint gatway só existe pro S3 e pro DynamoDB.
- Se o DNS privado estiver desligado, a placa do JOB fica sem rota e retorna erro "tempo esgotado".

## FASE 4
## ENUNCIADO 7:
- row id  = bigint         O crawler identificou que todos os valores eram numéricos e inteiros.
- postal code = bigint     O crawler identificou que todos os valores eram numéricos e inteiros.
- sales  = double          O crawler identificou que os valores eram numéricos e tinham casas decimais.
                           Obs. As demais são string para garantir que não hajam perdas nas informações.