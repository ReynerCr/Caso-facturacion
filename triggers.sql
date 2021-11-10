-- Script de creacion de triggers

SET SERVEROUTPUT ON;

commit;

-- 1. Tabla facturas
CREATE OR REPLACE TRIGGER tr_facturas
BEFORE INSERT OR UPDATE ON facturas
FOR EACH ROW
DECLARE
    codigo clientes.codcli%TYPE;
BEGIN
    -- si el cliente no existe no se devuelven filas y por tanto solo hay 
    -- que manejar la excepcion.
    SELECT codcli INTO codigo FROM clientes WHERE :NEW.codcli = clientes.codcli;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('CODIGO ' || codigo || ' NO ENCONTRADO');
END;
/

-- 2. Tabla lineas_fac
-- crear procedure o un bloque anonimo y agrupar los dos triggers?????
-- anyadir commits al final de las actualizaciones o inserciones DENTRO de los triggers
--drop trigger tr_lin_fac_bef;

-- Trigger UPDATE BEFORE de lineas_fac
CREATE OR REPLACE TRIGGER tr_lin_fac_bef
BEFORE INSERT OR UPDATE ON lineas_fac
FOR EACH ROW
DECLARE
    e_stock_insuficiente EXCEPTION;
    PRAGMA EXCEPTION_INIT (e_stock_insuficiente, -20001);
    stock articulos.stock%TYPE;
BEGIN
    -- si el articulo no existe no se devuelven filas y por tanto solo hay 
    -- que manejar la excepcion.
    SELECT stock INTO stock FROM articulos WHERE :NEW.codart = articulos.codart;
    
    -- validar disponibilidad del articulo.
    
    IF inserting THEN
        IF :NEW.cant > stock THEN
            RAISE e_stock_insuficiente;
        END IF;
    ELSE
        IF :OLD.cant != :NEW.cant AND :NEW.cant > stock + :OLD.cant THEN
            RAISE e_stock_insuficiente;
        END IF;
    END IF;
    /* OTRA FORMA DEL IF QUE EN TEORIA ES VALIDA PERO NINGUNA DE LAS DOS SIRVE
    IF ((inserting AND :NEW.cant > stock) OR 
        (updating AND :OLD.cant != :NEW.cant AND :NEW.cant > (stock + :OLD.cant)))
    THEN 
        RAISE e_stock_insuficiente;
    END IF;
    */    
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            DBMS_OUTPUT.PUT_LINE('Articulo no encontrado');
        WHEN e_stock_insuficiente THEN 
            DBMS_OUTPUT.PUT_LINE('Stock insuficiente.');
END;
/


SELECT * FROM articulos;
SELECT * FROM facturas WHERE codfac = 500;
SELECT * FROM lineas_fac WHERE codfac = 500 AND linea = 1;
DELETE FROM lineas_fac WHERE codfac = 500 AND linea = 1;

-- Pruebas con nueva factura y nueva linea de factura que tiene mayor cantidad
insert into facturas (codfac, fecha, codcli, iva, dto) values (500,sysdate,102,0,0);

SET SERVEROUTPUT ON;
insert into lineas_fac (codfac, linea, cant, codart, precio, dto) values (500,1,8,'T10027',7239,0);

insert into facturas (codfac, fecha, codcli, iva, dto) values (3000,to_date('16-11-1999','dd-mm-yyyy'),95,7,0);      

--DBMS_OUTPUT.PUT_LINE();