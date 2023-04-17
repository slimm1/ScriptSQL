-- script rollback agencia MRamonda --------------------------------------------------------------------------------------

USE agencia_de_viajes;

-- eliminar claves foraneas e indices -------------------------------------------------------------------------------------

ALTER TABLE alojamiento 
	DROP CONSTRAINT fk_alo_loc,
	DROP INDEX fk_alo_loc;

ALTER TABLE atraccion_turistica 
	DROP CONSTRAINT fk_att_loc,
	DROP INDEX fk_att_loc;
	
ALTER TABLE guia
	DROP CONSTRAINT fk_guia_att,
	DROP INDEX fk_guia_att,
	DROP CONSTRAINT fk_guia_loc,
	DROP INDEX fk_guia_loc;
	
ALTER TABLE guia_atraccion
	DROP CONSTRAINT fk_gui_att_att,
	DROP INDEX fk_gui_att_att,
	DROP CONSTRAINT fk_gui_att_guia;

ALTER TABLE localidad 
	DROP CONSTRAINT fk_loc_pre,
	DROP INDEX fk_loc_pre;
	
ALTER TABLE viaje
	DROP CONSTRAINT fk_vi_alo,
	DROP INDEX fk_vi_alo,
	DROP CONSTRAINT fk_vi_loc,
	DROP INDEX fk_vi_loc,
	DROP CONSTRAINT fk_vi_tran,
	DROP INDEX fk_vi_tran;

ALTER TABLE visita 
	DROP CONSTRAINT fk_vis_att,
	DROP INDEX fk_vis_att,
	DROP CONSTRAINT fk_vis_vi,
	DROP INDEX fk_vis_vi;

-- eliminar claves primarias -----------------------------------------------------------------------------------------------

ALTER TABLE alojamiento DROP PRIMARY KEY;
ALTER TABLE atraccion_turistica DROP PRIMARY KEY;
ALTER TABLE cliente DROP PRIMARY KEY;
ALTER TABLE guia DROP PRIMARY KEY;
ALTER TABLE guia_atraccion DROP PRIMARY KEY;
ALTER TABLE localidad DROP PRIMARY KEY;
ALTER TABLE precio DROP PRIMARY KEY;
ALTER TABLE transporte DROP PRIMARY KEY;
ALTER TABLE viaje DROP PRIMARY KEY;
ALTER TABLE visita DROP PRIMARY KEY;

-- añadir antiguos campos -------------------------------------------------------------------------------------------------

-- localidad en alojamiento y actualizo:
ALTER TABLE alojamiento ADD localidad VARCHAR(50);

UPDATE alojamiento a SET a.localidad = (
	SELECT l.nombre
	FROM localidad l
	WHERE a.cod_loc=l.COD
);

-- localidad en atraccion y actualizo:
ALTER TABLE atraccion_turistica ADD localidad VARCHAR(50);

UPDATE atraccion_turistica a SET a.localidad= (
	SELECT l.nombre
	FROM localidad l
	WHERE a.cod_loc = l.cod
);

-- actualizar viaje:
ALTER TABLE viaje 
	ADD nombre_alojamiento VARCHAR(50),
	ADD tipo_alojamiento VARCHAR(20),
	ADD localidad VARCHAR(50),
	ADD dni_cliente VARCHAR(9);

UPDATE viaje v SET v.nombre_alojamiento = (
	SELECT a.NOMBRE
	FROM alojamiento a
	WHERE v.cod_alojamiento = a.cod
);

UPDATE viaje v SET v.tipo_alojamiento = (
	SELECT a.TIPO
	FROM alojamiento a
	WHERE v.cod_alojamiento = a.cod
);

UPDATE viaje v SET v.localidad = (
	SELECT l.NOMBRE
	FROM localidad l
	WHERE v.cod_loc = l.COD
);

UPDATE viaje v SET v.dni_cliente = (
	SELECT c.DNI
	FROM cliente c
	WHERE v.cod_cliente = c.cod
);

-- actualizar visita:
ALTER TABLE visita
	ADD DNI_CLIENTE VARCHAR(9),
	ADD NOMBRE_ALOJAMIENTO VARCHAR(50),
	ADD TIPO_ALOJAMIENTO VARCHAR(20),
	ADD LOCALIDAD_VIAJE VARCHAR(50),
	ADD FECHA_SALIDA_VIAJE DATETIME,
	ADD LOCALIDAD_ATRACCION_TURISTICA VARCHAR(50),
	ADD NOMBRE_ATRACCION_TURISTICA VARCHAR(50);
	
UPDATE visita v SET v.DNI_CLIENTE = (
	SELECT c.DNI
	FROM viaje vi JOIN cliente c ON vi.cod_cliente = c.cod
	WHERE v.cod_viaje = vi.cod
);

UPDATE visita v SET v.nombre_alojamiento = (
	SELECT a.NOMBRE
	FROM viaje vi JOIN alojamiento a ON vi.cod_alojamiento = a.cod
	WHERE v.cod_viaje = vi.cod
);

UPDATE visita v SET v.tipo_alojamiento = (
	SELECT a.TIPO
	FROM viaje vi JOIN alojamiento a ON vi.cod_alojamiento = a.cod
	WHERE v.cod_viaje = vi.cod
);

UPDATE visita v SET v.localidad_viaje = (
	SELECT l.NOMBRE
	FROM viaje vi JOIN localidad l ON vi.cod_loc = l.COD
	WHERE v.cod_viaje = vi.cod
);

UPDATE visita v SET v.fecha_salida_viaje = (
	SELECT vi.FECHA_SALIDA
	FROM viaje vi
	WHERE v.cod_viaje = vi.cod
);

UPDATE visita v SET v.localidad_atraccion_turistica = (
	SELECT l.NOMBRE
	FROM atraccion_turistica a JOIN localidad l ON a.cod_loc = l.COD
	WHERE v.cod_atraccion = a.cod
);

UPDATE visita v SET v.nombre_atraccion_turistica = (
	SELECT a.NOMBRE
	FROM atraccion_turistica a 
	WHERE v.cod_atraccion = a.cod
);
-- establecer claves primarias --------------------------------------------------------------------------------------------

ALTER TABLE cliente ADD PRIMARY KEY(dni);

ALTER TABLE alojamiento ADD PRIMARY KEY(nombre, tipo);

ALTER TABLE viaje ADD PRIMARY KEY(DNI_CLIENTE, NOMBRE_ALOJAMIENTO, TIPO_ALOJAMIENTO, LOCALIDAD, FECHA_SALIDA);

ALTER TABLE atraccion_turistica ADD PRIMARY KEY(LOCALIDAD, NOMBRE);

ALTER TABLE visita ADD PRIMARY KEY(DNI_CLIENTE, LOCALIDAD_ATRACCION_TURISTICA, NOMBRE_ATRACCION_TURISTICA);

-- eliminar columnas y tablas sobrantes ------------------------------------------------------------------------------------

ALTER TABLE alojamiento 
	DROP cod,
	DROP cod_loc;
	
ALTER TABLE atraccion_turistica 
	DROP cod,
	DROP cod_loc;

ALTER TABLE cliente DROP cod;

ALTER TABLE viaje 
	DROP cod,
	DROP cod_transporte,
	DROP cod_loc,
	DROP cod_alojamiento,
	DROP cod_cliente;

ALTER TABLE visita
	DROP cod,
	DROP cod_viaje,
	DROP cod_atraccion;

DROP TABLE guia;

DROP TABLE guia_atraccion;

DROP TABLE precio;

DROP TABLE transporte;

DROP TABLE localidad;

DROP VIEW date_checker;

-- modificar las claves foraneas -----------------------------------------------------------------------------------------------

ALTER TABLE VIAJE ADD CONSTRAINT FK_VIJ_CLI FOREIGN KEY (DNI_CLIENTE) REFERENCES CLIENTE(DNI);
ALTER TABLE VIAJE ADD CONSTRAINT FK_VIJ_ALO FOREIGN KEY (NOMBRE_ALOJAMIENTO, TIPO_ALOJAMIENTO) REFERENCES ALOJAMIENTO(NOMBRE, TIPO);

ALTER TABLE VISITA ADD CONSTRAINT FK_VIS_VIJ FOREIGN KEY (DNI_CLIENTE, NOMBRE_ALOJAMIENTO, TIPO_ALOJAMIENTO, LOCALIDAD_VIAJE, FECHA_SALIDA_VIAJE) REFERENCES VIAJE(DNI_CLIENTE, NOMBRE_ALOJAMIENTO, TIPO_ALOJAMIENTO, LOCALIDAD, FECHA_SALIDA);
ALTER TABLE VISITA ADD CONSTRAINT FK_VIS_ATT FOREIGN KEY (LOCALIDAD_ATRACCION_TURISTICA, NOMBRE_ATRACCION_TURISTICA) REFERENCES ATRACCION_TURISTICA(LOCALIDAD, NOMBRE);



