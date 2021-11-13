create table  provincias
( codpro    varchar2(2),
  nombre    varchar2(30),
constraint cp_provincias primary key (codpro));

create table  pueblos
( codpue    varchar2(5),
  nombre    varchar2(40),
  codpro    varchar2(2),
constraint cp_pueblos primary key (codpue),
constraint ca_pue_pro foreign key (codpro) references provincias);

create table  clientes
( codcli    number(5),
  nombre    varchar2(50),
  direccion varchar2(50),
  codpostal varchar2(5),
  codpue    varchar2(5),
constraint cp_clientes primary key (codcli),
constraint ca_cli_pue foreign key (codpue) references pueblos);

create table  articulos
( codart    varchar2(8),
  descrip   varchar2(40),
  precio    number(6,1),
  stock     number(6),
  stock_min number(6),
constraint cp_articulos primary key (codart));

create table  facturas
( codfac    number(6),
  fecha     date,
  codcli    number(5),
  iva       number(2),
  dto       number(2),
constraint cp_facturas primary key (codfac),
constraint ca_fac_cli foreign key (codcli) references clientes,
constraint ri_iva check ( iva in (0,7,16) ),
constraint ri_dto_fac check ( dto between 0 and 50 ) );

create table  lineas_fac
( codfac    number(6),
  linea     number(2),
  cant      number(5),
  codart    varchar2(8),
  precio    number(6,1),
  dto       number(2),
constraint cp_lineas_fac primary key (codfac,linea),
constraint ca_lin_fac foreign key (codfac) references facturas,
constraint ca_lin_art foreign key (codart) references articulos,
constraint ri_dto_lin check ( dto between 0 and 50 ) );
