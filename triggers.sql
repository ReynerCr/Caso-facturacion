-- Script de creacion de triggers

SET SERVEROUTPUT ON;

commit;

-- 1. Tabla facturas
-- En teoria este trigger no es necesario, ya se verifica porque es FK de una PK
-- Trigger BEFORE INSERT OR UPDATE de facturas
CREATE OR REPLACE TRIGGER tr_facturas
BEFORE INSERT OR UPDATE ON facturas
FOR EACH ROW
DECLARE
    codigo clientes.codcli%TYPE;
BEGIN
    -- si el cliente no existe se devuelve excepcion de NO_DATA_FOUND
    SELECT codcli INTO codigo FROM clientes WHERE :NEW.codcli = clientes.codcli;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Codigo de cliente ' || :NEW.codcli || ' no encontrado');
            RAISE_APPLICATION_ERROR(-20001,'Codigo de cliente no encontrado.');
END;
/

-- Pruebas basicas de funcionalidad
SELECT * FROM clientes WHERE codcli = 95; -- Comprobar que cliente no existe
INSERT INTO facturas (codfac, fecha, codcli, iva, dto)
    VALUES (3000,to_date('16-11-1999','dd-mm-yyyy'),95,7,0);     
UPDATE facturas SET codcli = 95 WHERE codfac = 1;


-- 2. Tabla lineas_fac  ------------------------------------------------------
-- Trigger BEFORE INSERT OR UPDATE de lineas_fac
CREATE OR REPLACE TRIGGER tr_lin_fac_bef
BEFORE INSERT OR UPDATE ON lineas_fac
FOR EACH ROW
DECLARE
    e_stock_insuficiente EXCEPTION;
    PRAGMA EXCEPTION_INIT (e_stock_insuficiente, -20003);
    stock articulos.stock%TYPE;
BEGIN
    -- si el articulo no existe se devuelve excepcion de NO_DATA_FOUND
    SELECT stock INTO stock FROM articulos WHERE :NEW.codart = articulos.codart;
    
    -- validar disponibilidad del articulo.
    IF ((inserting AND :NEW.cant > stock) OR 
        (updating AND :OLD.cant != :NEW.cant AND :NEW.cant > (stock + :OLD.cant)))
    THEN 
        RAISE e_stock_insuficiente;
    END IF;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            DBMS_OUTPUT.PUT_LINE('Articulo no encontrado o no valido.');
            RAISE_APPLICATION_ERROR(-20002,'Codigo de articulo no encontrado o no valido.');
        WHEN e_stock_insuficiente THEN 
            DBMS_OUTPUT.PUT_LINE('Stock insuficiente.');
            RAISE_APPLICATION_ERROR(-20003,'Stock insuficiente.');
END;
/

/* --DELETE
DELETE FROM facturas WHERE codfac = 500;
DELETE FROM lineas_fac WHERE codfac = 500 AND linea = 1; 
*/

-- Pruebas basicas de funcionalidad
INSERT INTO facturas (codfac, fecha, codcli, iva, dto) VALUES (500,sysdate,102,0,0);
SELECT * FROM articulos WHERE codart = 'T10027'; -- Comprobar datos de stock
INSERT INTO lineas_fac (codfac, linea, cant, codart, precio, dto)
    VALUES (500,1,8,'T10027',7239,0); -- prueba de stock insuficiente
INSERT INTO lineas_fac (codfac, linea, cant, codart, precio, dto)
    VALUES (500,1,7,'T10027',7239,0); -- valido
    
    -- Prueba de codigo de articulo invalido (no existente)
UPDATE lineas_fac SET codart = 'P001' WHERE codart = 'T10027' AND linea = 1;
UPDATE lineas_fac SET codart = NULL WHERE codart = 'T10027' AND linea = 1;


-- NOTAS PENDIENTES
-- Falta trigger o triggers de AFTER
-- crear procedure o un bloque anonimo y agrupar los dos triggers de lineas_fac?????
-- anyadir commits al final de las actualizaciones o inserciones DENTRO del trigger de lineas_fac
