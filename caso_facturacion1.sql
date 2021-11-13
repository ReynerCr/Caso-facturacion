/*
    Creado por los equipos 3 y 4
    Base de datos I sección 1 2021-3
    
    Autores:
    Camargo Meaury, Franklin Josue; C.I: V.-27655989
    Contreras Rojas, Reyner David;  C.I: V.-26934400
    Vargas Rueda, Brandon Jose; C.I: V.-26566047
*/

--2 --------------------------------------------------------------------------

--2.1 Obtener el codigo y el doble del precio de los articulos cuyo precio es inferior a 5 centimos de euro.
SELECT codart "Codigo de articulo", (precio*2) "Doble del precio"
FROM articulos WHERE (precio < 0.05);

--2.2
/*
    Obtener el codigo de factura y de articulo de las lineas de factura en las que la cantidad solicitada es
    menor de 2 unidades y ademas se ha aplicado un descuento del 50% o mayor.
*/
SELECT codfac "Codigo de factura", codart "Codigo de articulo" FROM lineas_fac
WHERE (cant < 2) AND (dto >= 50);

--2.3
/*
    Obtener la descripcion de los artoculos cuyo stock esta por debajo de su stock minimo, mostrando
    tambien la cantidad en unidades necesaria para que el stock alcance dicho minimo.
*/
-- Cantidad necesaria se refiere a cantidad necesaria para cumplir con el minimo
SELECT descrip "Descripcion", (stock_min - stock) "Cantidad necesaria"
FROM articulos WHERE (stock < stock_min);

--2.4 Numero de pueblos en los que residen clientes cuyo codigo postal empieza por 12.
SELECT COUNT(DISTINCT codpue) "Nro. pueblos distintos '12%'"
FROM clientes WHERE codpostal LIKE '12%';

--2.5 Codigos de los clientes de la provincia de Castellon (codigo de provincia '12') que no tienen facturas.
-- clipuebc son los clientes que son de castellon, TODOS
SELECT clipuebc.codcli FROM 
(SELECT cli.codcli
    FROM clientes cli
    JOIN pueblos pue
    ON (pue.codpro = '12' AND cli.codpue = pue.codpue)
) clipuebc WHERE clipuebc.codcli  NOT IN (SELECT codcli FROM facturas);
/* OTRA FORMA
SELECT clipuebc.codcli FROM
    (
        SELECT clientes.codcli FROM clientes WHERE clientes.codpue IN 
        (SELECT pueblos.codpue FROM pueblos WHERE pueblos.codpro = '12')
    ) clipuebc
WHERE clipuebc.codcli NOT IN (SELECT codcli FROM facturas);
*/

--2.6
/*
    Mostrar valores maximo y minimo del stock de los articulos cuyo precio oscila entre 9 y 12 euros y la
    diferencia entre ambos valores
*/
-- no hay un stock maximo, asi que se utilizara stock
SELECT stock, stock_min "Stock minimo",
    (stock - stock_min) "Diferencia"
FROM articulos WHERE precio BETWEEN 9 AND 12;

--2.7
/*
    Visualizar un listado de los articulos de menos de un euro con su codigo y un mensaje que indique la
    situacion de su stock. Cuando el stock sea superior al stock minimo hay que escribir 'STOCK
    SUFICIENTE', si es igual escribir 'STOCK AJUSTADO', y si el stock minimo es mayor que el
    stock, escribir el mensaje 'STOCK INSUFICIENTE'.
*/
SELECT codart, stock, stock_min,
    CASE SIGN(stock - stock_min) WHEN -1 THEN 'STOCK INSUFICIENTE'
    WHEN 0 THEN 'STOCK AJUSTADO'
    ELSE 'STOCK SUFICIENTE' END "Situacion"
FROM articulos WHERE (precio < 1);

--2.8
/*
    Para cada factura del mes de Agosto del anyo 1999, se desea obtener el codigo de la factura,
    fecha y nombre del vendedor, ordenando el resultado por nombre de vendedor en primer lugar y despues
    por codigo de factura.
*/
-- no existe el atributo de vendedor, se pensara que se referia a cliente
SELECT codfac "Codigo factura", fecha "Fecha", clientes.nombre "Nombre cliente"
FROM facturas, clientes WHERE facturas.fecha LIKE '_%/08/99'
ORDER BY nombre, codfac;

--3 --------------------------------------------------------------------------

--3.1 Se desea conocer el numero de facturas para cada anyo. Se debe mostrar el anyo y el numero de facturas de ese anyo.
SELECT COUNT(codfac), REGEXP_SUBSTR(fecha, '\d\d$') Annio
FROM facturas GROUP BY (REGEXP_SUBSTR(fecha, '\d\d$')) ORDER BY Annio;

--3.2
/*
    Se desea conocer por nombre del cliente la cantidad de facturas procesada,
    pero solo se deben mostrar aquellos clientes que tienen mas del promedio de
    las facturas del pueblo de 'ARAYA'.
    
    Por lo que entendi debo obtener nombre del cliente y cantidad de facturas PARA
    TODOS los clientes PERO cuya cantidad de facturas sea mayor al promedio 
    de facturas del pueblo 'ARAYA'.
*/
SELECT cli.nombre, COUNT(fac.codfac) cantidad
FROM facturas fac
INNER JOIN clientes cli
ON cli.codcli = fac.codcli
GROUP BY cli.codcli, cli.nombre
HAVING COUNT(fac.codfac) > 
        (SELECT AVG(cliaraya.cant) FROM
            (
                SELECT COUNT(fac.codfac) cant
                FROM clientes cli
                INNER JOIN pueblos pue
                ON pue.nombre = 'ARAYA' AND pue.codpue = cli.codpue
                JOIN facturas fac
                ON cli.codcli = fac.codcli
                GROUP BY cli.codcli, cli.nombre
            ) cliaraya
        );

--3.3 Se desea visualizar por cliente y fecha la cantidad de facturas y el monto facturado.
SELECT fac.codcli "Codigo de cliente", fac.fecha,
    COUNT(DISTINCT fac.codfac) "Nro de facturas",
    SUM(
        lin.cant * lin.precio * 
        (1 - (COALESCE(lin.dto, 0) + COALESCE(fac.dto,0) - COALESCE(fac.iva,0)) / 100)
    ) "Monto total"
FROM facturas fac
RIGHT JOIN lineas_fac lin
ON fac.codfac = lin.codfac
GROUP BY fac.codcli, fac.fecha
ORDER BY fac.fecha, fac.codcli;

-- 3.4 Se desea visualizar por pueblo, cliente, la cantidad de facturas, el monto facturado, el minimo facturado y el maximo facturado.
-- facmontos tiene como resultado los montos de cada facutra por cliente
SELECT pue.nombre "Pueblo", facmontos.codcli "Codigo de cliente",
    COUNT(DISTINCT facmontos.codfac) "Nro de facturas", SUM(facmontos.monto) "Monto total",
    MIN(facmontos.monto) "Monto minimo", MAX(facmontos.monto) "Monto maximo"
FROM
(
    SELECT fac.codcli, fac.codfac,
    SUM(
        lin.cant * lin.precio * 
        (1 - (COALESCE(lin.dto, 0) + COALESCE(fac.dto,0) - COALESCE(fac.iva,0)) / 100)
    ) monto
    FROM facturas fac
    RIGHT JOIN lineas_fac lin
    ON fac.codfac = lin.codfac
    GROUP BY fac.codcli, fac.codfac
    ORDER BY fac.codcli, fac.codfac
) facmontos
INNER JOIN clientes cli
ON facmontos.codcli = cli.codcli
INNER JOIN pueblos pue
ON pue.codpue = cli.codpue
GROUP BY pue.nombre, facmontos.codcli
ORDER BY pue.nombre, facmontos.codcli;

--3.5
/*
    Consultar los nombres de las provincias con mas de 500 pueblos y en las que hay mas de 5 pueblos
    con clientes.
*/
SELECT provfilttotal.nombre FROM 
(
    SELECT provpuefilt.nombre, COUNT(provpuefilt.codpro) countcliprov
    FROM clientes cli
    INNER JOIN
    (
        SELECT provpue.nombre, pue.codpue, provpue.codpro FROM
        (
            SELECT prov.nombre, pue.codpro, COUNT(pue.codpue) contpueprov
            FROM pueblos pue
            JOIN provincias prov
            ON pue.codpro = prov.codpro
            GROUP BY prov.nombre, pue.codpro
        ) provpue
        INNER JOIN pueblos pue
        ON contpueprov > 500 AND provpue.codpro = pue.codpro
    ) provpuefilt
    ON cli.codpue = provpuefilt.codpue
    GROUP BY provpuefilt.nombre
    ORDER BY provpuefilt.nombre
) provfilttotal WHERE provfilttotal.countcliprov > 5;

--3.6
/*
    Visualizar el nombre del cliente, codigo postal y monto total facturado, sin tener en cuenta impuestos
    ni descuentos, de aquellos clientes que han facturado igual o mas de los facturado en el mes de
    diciembre del anyo 1998.
    
    clientesmon son todos los clientes con la sumatoria de todas sus facturas SIN descuentos e iva
    la subquery en HAVING devuelve la sumatoria total de montos facturados en diciembre del 98 CON descuentos e iva
*/
SELECT cli.nombre, cli.codpostal, clientesmon.monfac
FROM
    (
        SELECT fac.codcli,
            SUM(lin.cant * lin.precio) monfac
        FROM facturas fac
        RIGHT JOIN lineas_fac lin
        ON fac.codfac = lin.codfac
        GROUP BY fac.codcli
    ) clientesmon
INNER JOIN clientes cli
ON cli.codcli = clientesmon.codcli
GROUP BY cli.nombre, cli.codpostal, clientesmon.monfac
HAVING clientesmon.monfac >= (
            SELECT
                SUM(
                    lin.cant * lin.precio * 
                    (1 - (COALESCE(lin.dto, 0) + COALESCE(fac.dto,0) - COALESCE(fac.iva,0)) / 100)
                ) monto
            FROM facturas fac
            INNER JOIN lineas_fac lin
            ON fac.fecha LIKE ('%_/12/98') AND fac.codfac = lin.codfac
        );
        
--3.7
/*
    Se desea consultar el nombre de cada cliente y el numero de unidades que ha comprado (suma de las
    cantidades de las lineas de sus facturas), pero solo si el total supera el minimo de las unidades
    compradas en la provincia de ALICANTE. Utiliza la clausula JOIN.
*/
SELECT clicant.nombre, clicant.cantidadt
FROM
(
    SELECT cli.nombre, cli.codcli,
        SUM(lin.cant) cantidadt
    FROM facturas fac
    INNER JOIN lineas_fac lin
    ON fac.codfac = lin.codfac
    INNER JOIN clientes cli
    ON fac.codcli = cli.codcli
    GROUP BY cli.nombre, cli.codcli
) clicant
WHERE cantidadt > 
    (
        SELECT MIN(cantidadt) FROM
        (
            SELECT clicant.nombre, clicant.cantidadt
            FROM
            (
                SELECT cli.nombre, cli.codcli, cli.codpue,
                    SUM(lin.cant) cantidadt
                FROM facturas fac
                INNER JOIN lineas_fac lin
                ON fac.codfac = lin.codfac
                INNER JOIN clientes cli
                ON fac.codcli = cli.codcli
                GROUP BY cli.nombre, cli.codcli, cli.codpue
                ORDER BY cantidadt
            ) clicant
            INNER JOIN pueblos pue
            ON clicant.codpue = pue.codpue
            INNER JOIN provincias prov
            ON pue.codpro = prov.codpro AND prov.nombre = 'ALICANTE'
        )
    )
ORDER BY cantidadt;