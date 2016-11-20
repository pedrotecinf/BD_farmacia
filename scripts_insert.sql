
-- insert into pessoa(nome, sexo, CPF, telefone) values("touka","F","245.146.145-14","69 99999-9999");
delimiter $$
drop procedure if exists InsertPessoa$$
create procedure InsertPessoa(in p_nome varchar(45), in p_sexo varchar(1), in p_cpf int(14), in telefone int(13), out msg varchar(30))
begin 

end $$;
delimiter ;

-- insert into cliente() values();
insert into cliente values(2);

-- insert into funcao_funcionario() values();
insert into funcao_funcionario(tipo) values("vendedor");

-- insert into funcionario() values();
 insert into funcionario (fun_id_funcao, fun_id_pessoa) values (1,1);
 
-- insert into medico() values();
insert into medico(med_id_pessoa, CRM) values(3,"12345678");

-- insert into categoria() values();
-- insert into produtos() values();
-- insert into fornecedor() values();
-- insert into estoque() values();

-- insert into carrinho() values();
-- insert into venda() values();