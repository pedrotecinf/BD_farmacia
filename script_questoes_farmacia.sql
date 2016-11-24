
-- formatador de cpf para que fique de modo padrão
DELIMITER $$
DROP FUNCTION IF EXISTS format_cpf$$
CREATE FUNCTION format_cpf(cpf VARCHAR(11))
RETURNS VARCHAR(14)
    BEGIN
        RETURN CONCAT( SUBSTRING(cpf,1,3) , '.',
            SUBSTRING(cpf,4,3), '.',
            SUBSTRING(cpf,7,3), '-',
            SUBSTRING(cpf,10,2));
END $$
DELIMITER ;

--  2 VALIDADOR DE CPF MAS PARA ISSO TEM QUE ESTAR NO FORMATO XXX.XXX.XXX-XX PARA ISSO USAR A FUNÇÃO ANTERIOR
delimiter $$
drop function if exists cpf_v$$
create function cpf_v ( cpf varchar(14)) returns varchar(8)
begin
	set @dig_cpf=substr(cpf,13,2);
	set @dig_v = CONCAT( @dig1:=(
      SUBSTR(cpf, 1,1)   + SUBSTR(cpf, 2,1)*2 + SUBSTR(cpf, 3,1)*3 +
      SUBSTR(cpf, 5,1)*4 + SUBSTR(cpf, 6,1)*5 + SUBSTR(cpf, 7,1)*6 +
      SUBSTR(cpf, 9,1)*7 + SUBSTR(cpf,10,1)*8 + SUBSTR(cpf,11,1)*9 ) % 11 % 10
   ,(
      SUBSTR(cpf, 2,1)   + SUBSTR(cpf, 3,1)*2 + SUBSTR(cpf, 5,1)*3 +
      SUBSTR(cpf, 6,1)*4 + SUBSTR(cpf, 7,1)*5 + SUBSTR(cpf, 9,1)*6 +
      SUBSTR(cpf,10,1)*7 + SUBSTR(cpf,11,1)*8 + @dig1           *9 ) % 11 % 10
   );
	if (@dig_v= @dig_cpf)then
    return "valido";
    else return "invalido";
    end if;
end$$
delimiter ;

-- 3 FUNÇÃO QUE VERIFICA SE EXISTE CPF JA CADASTRADO
DELIMITER $$
DROP FUNCTION IF EXISTS VERIFICA_CPF_EXIST$$
CREATE FUNCTION VERIFICA_CPF_EXIST(F_CPF VARCHAR(14))
RETURNS BOOLEAN
BEGIN
DECLARE QTD INT;
SET QTD= (SELECT COUNT(CPF) FROM pessoa WHERE CPF= F_CPF);
	IF(QTD >0)THEN
    RETURN TRUE; 
    ELSE
    RETURN FALSE; 
    END IF;
END $$
DELIMITER ;

-- 4 Uma Trigger que irá chamar as duas funções anteriores com finalidade de evitar cadastro de CPF incorreto ou repetido.
DELIMITER $$
DROP TRIGGER IF EXISTS VERIFICADOR_CPF$$
CREATE TRIGGER VERIFICADOR_CPF BEFORE INSERT
ON PESSOA
FOR EACH ROW
BEGIN
	IF(character_length(NEW.CPF) = 11 )THEN
		set NEW.CPF = format_cpf(NEW.CPF);
        SELECT VERIFICA_CPF_EXIST(NEW.CPF);
        SELECT cpf_v(NEW.CPF);
    END IF;
END $$
DELIMITER ; 

-- 5 Além da trigger do item 4, deverá conter pelo menos uma trigger para cada evento (INSERT, UPDATE E DELETE). 

-- TRIGGER DE DELETE -------------------------------------------------------------------------------------^
DELIMITER $$
DROP TRIGGER IF EXISTS EXCLUSAO_CARRINHO$$
CREATE TRIGGER EXCLUSAO_CARRINHO AFTER DELETE
ON carrinho
FOR EACH ROW
BEGIN
	UPDATE estoque 
		SET QTD_estoque= (QTD_estoque+qtd_pedido)
			WHERE carr_id_estoque= id_estoque;
END $$
DELIMITER ;																							
-- TRIGGER DE UPDATE ------------------------------------------------------------------------------^
DELIMITER $$
DROP TRIGGER IF EXISTS UPDATE_NO_ESTOQUE$$
CREATE TRIGGER UPDATE_NO_ESTOQUE AFTER UPDATE
ON estoque
FOR EACH ROW
BEGIN
	IF(NEW.QTD_estoque>0)THEN
		UPDATE estoque 
			SET NEW.QTD_estoque= (OLD.QTD_estoque+NEW.QTD_estoque)
				WHERE NEW.id_estoque= OLD.id_estoque;
	END IF ;
END $$
DELIMITER ;
-- TRIGGER DE INSERT
DELIMITER $$
DROP TRIGGER IF EXISTS INSERT_NO_ESTOQUE1$$
CREATE TRIGGER INSERT_NO_ESTOQUE1 BEFORE INSERT
ON estoque
FOR EACH ROW
BEGIN
	SET NEW.dataRegistro=curdate();
    
END $$
DELIMITER ;
-- alternativo ao anterior
DELIMITER $$
DROP TRIGGER IF EXISTS INSERT_NO_ESTOQUE2$$
CREATE TRIGGER INSERT_NO_ESTOQUE2 AFTER INSERT
ON estoque
FOR EACH ROW
BEGIN
	SET NEW.dataRegistro=curdate();
    IF( dataRegisto IS  NULL )THEN
		UPDATE estoque 
			SET dataRegisto=CURDATE()
				WHERE NEW.id_estoque;
	END IF ;
	
END $$
DELIMITER ;

-- – Deverá conter, no mínimo, dois procedimentos e pelo menos mais uma função além das duas solicitadas nos itens 2 e 3. 
delimiter $$
drop procedure if exists InsertPessoa$$
create procedure InsertPessoa(in p_nome varchar(45), in p_sexo varchar(1), in p_cpf int(11), in p_telefone int(13), out msg varchar(30))
begin 
declare cpf_formatado varchar(14);
set cpf_formatado = format_cpf(p_cpf);
	if(p_cpf<11)then
    set msg="Insira somente numeros no cpf não coloque . ou - ";
    elseif(cpf_v(cpf_formatado) = "valido")then
    insert into pessoa( nome, sexo, CPF, telefone) values(p_nome, p_sexo, cpf_formatado, telefone);
    elseif(cpf_v(cpf_formatado) = "invalido")then
    select "CPF INVALIDO";
    end if;
end $$;
delimiter ;

delimiter $$
drop procedure if exists InsertEstoque$$
create procedure InsertEstoque(in idProd int, in idCateg int, in id_forn int, in QTD int, in precoUni double(10,2), in dt_validade date)
begin 
    insert into estoque( est_id_produto, est_id_categoria, est_id_Form, QTD_estoque, precoUni, data_venc) 
    values(idProd, idCateg, id_forn, QTD,precoUni, dt_validade);    
end $$
delimiter ;


--  Deverá conter pelos menos três View funcionais (relevantes). 


create view `ESTOQUE_PRODUTOS` as
  select
  nome as produto,
  QTD_estoque as quantidade,
  precoUni as precoUnitario,
  (QTD_estoque* precoUni) as PrecoTotal  
  from
  estoque, produto
  where
  est_id_produto=produto.id_produto;

select *from ESTOQUE_PRODUTOS;

create view `ESTOQUE_FORNECEDOR` as
  select
  nome as produto,
  QTD_estoque as quantidade,
  tipo as Categoria_produto,
  fornecedor,
  CNPJ    
  from
  estoque, produto, categoria, Fornecedor
  where
  est_id_produto=id_produto
  and
  est_id_categoria=id_categoria
  and
  est_id_Forn=id_Forn;

select *from ESTOQUE_FORNECEDOR;

create view `venda_view` as
  select
  pessoa.nome as Nome_Pessoa,
  produto.nome as produto,
  Tipo as categoria,
  qtd_pedido as quantidade_produto,
  precoUni as valor_produto,
  total    
  from
  pessoa,cliente,venda, carrinho, estoque, produto, categoria
  where
  id_pessoa=cli_id_pessoa
  and
  idcliente=vend_idcliente
  and
  id_carrinho=vend_id_carrinho
   and
  id_estoque=carr_id_estoque
  and
  est_id_produto=id_produto
  and
  est_id_categoria=id_categoria ;

select *from venda_view