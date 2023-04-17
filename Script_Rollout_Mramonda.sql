-- script rollout agencia MRamonda --------------------------------------------------------------------------------------

USE agencia_de_viajes;

-- eliminar claves foraneas e indices -------------------------------------------------------------------------------------

ALTER TABLE viaje DROP CONSTRAINT FK_VIJ_CLI;
ALTER TABLE viaje DROP CONSTRAINT FK_VIJ_ALO;
ALTER TABLE viaje DROP INDEX FK_VIJ_ALO;

ALTER TABLE visita DROP CONSTRAINT FK_VIS_VIJ;
ALTER TABLE visita DROP CONSTRAINT FK_VIS_ATT;
ALTER TABLE visita DROP INDEX FK_VIS_VIJ;
ALTER TABLE visita DROP INDEX FK_VIS_ATT;

-- eliminar claves primarias -----------------------------------------------------------------------------------------------

ALTER TABLE alojamiento DROP PRIMARY KEY;
ALTER TABLE atraccion_turistica DROP PRIMARY KEY;
ALTER TABLE cliente DROP PRIMARY KEY;
ALTER TABLE viaje DROP PRIMARY KEY;
ALTER TABLE visita DROP PRIMARY KEY;

-- claves primarias -------------------------------------------------------------------------------------------------------------

-- alojamiento:
ALTER TABLE alojamiento ADD cod VARCHAR(36) PRIMARY KEY DEFAULT UUID() FIRST;

-- atraccion:
ALTER TABLE atraccion_turistica ADD cod VARCHAR(36) PRIMARY KEY DEFAULT UUID() FIRST;

-- viaje:
ALTER TABLE viaje ADD cod VARCHAR(36) PRIMARY KEY DEFAULT UUID() FIRST;

-- visita:
ALTER TABLE visita ADD cod VARCHAR(36) PRIMARY KEY DEFAULT UUID() FIRST;

-- cliente:
ALTER TABLE cliente ADD cod VARCHAR(36) PRIMARY KEY DEFAULT UUID() FIRST;

-- creacion tabla transporte ------------------------------------------------------------------------------------------------

CREATE OR REPLACE TABLE transporte(
	cod VARCHAR(36) PRIMARY KEY DEFAULT UUID(),
	medio_transporte VARCHAR(20)
);

-- insertar valores en la tabla transporte:
INSERT INTO transporte(medio_transporte) VALUES('COCHE'),('TREN'),('AVION'),('AUTOBUS');

-- añadir columna medio tranporte en viaje:
ALTER TABLE viaje ADD cod_transporte VARCHAR(36);

-- actualizar datos en tabla viaje:
UPDATE viaje SET cod_transporte = (
	SELECT t.cod
	FROM transporte t	
	WHERE t.medio_transporte LIKE('COCHE')
);

-- crear tabla precios -----------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TABLE precio(
	cod VARCHAR(36) PRIMARY KEY DEFAULT UUID(),
	tipo VARCHAR(10)
);

-- insertar datos en precio:
INSERT INTO precio(tipo) VALUES('ALTO'),('MEDIO'),('BAJO');

-- crear tabla localidad ---------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TABLE LOCALIDAD(
	COD VARCHAR(36) PRIMARY KEY DEFAULT UUID(),
	NOMBRE VARCHAR(50),
	PAIS VARCHAR(30),
	cod_precio VARCHAR(36)
); 

-- rellenar la tabla localidad ---------------------------------------------------------------------------------------------------

INSERT INTO localidad(nombre)
    SELECT a.localidad
    FROM alojamiento a
    UNION
    SELECT atr.localidad
    FROM atraccion_turistica atr
    UNION
    SELECT v.localidad
    FROM viaje v
    UNION
    SELECT vs.localidad_viaje
    FROM visita vs
    UNION
    SELECT vs2.LOCALIDAD_ATRACCION_TURISTICA
    FROM visita vs2
;

-- actualizar pais para la tabla localidad-----------------------------------------------------------------------------------------

UPDATE localidad SET pais = 'ESPAÑA' WHERE pais IS NULL;

-- update en tabla visita para referenciar atraccion -------------------------------------------------------------------------------

ALTER TABLE visita ADD cod_atraccion VARCHAR(36);

	UPDATE visita v 
	SET v.cod_atraccion = (
		SELECT a.cod
		FROM atraccion_turistica a
		WHERE v.LOCALIDAD_ATRACCION_TURISTICA LIKE(a.LOCALIDAD)
		&& v.NOMBRE_ATRACCION_TURISTICA LIKE(a.NOMBRE)
	);

-- updates en las tablas que usan datos de localidad --------------------------------------------------------------------------------

-- alojamiento:
ALTER TABLE alojamiento ADD cod_loc VARCHAR(36);

	UPDATE alojamiento a 
	SET a.cod_loc = (
		SELECT l.cod
		FROM localidad l 
		WHERE a.LOCALIDAD LIKE l.NOMBRE
	);	

-- atraccion:
ALTER TABLE atraccion_turistica ADD cod_loc VARCHAR(36);

	UPDATE atraccion_turistica a 
	SET a.cod_loc = (
		SELECT l.cod
		FROM localidad l 
		WHERE a.LOCALIDAD LIKE(l.NOMBRE)
	);

-- viaje:
ALTER TABLE viaje ADD cod_loc VARCHAR(36);

	UPDATE viaje v
	SET v.cod_loc = (
		SELECT l.cod
		FROM localidad l
		WHERE v.LOCALIDAD LIKE(l.NOMBRE) 
	);

-- update en tabla viaje para referenciar alojamiento -----------------------------------------------------------------

ALTER TABLE viaje ADD cod_alojamiento VARCHAR(36);

	UPDATE viaje v
	SET v.cod_alojamiento = (
		SELECT a.cod
		FROM alojamiento a
		WHERE v.NOMBRE_ALOJAMIENTO LIKE(a.NOMBRE)
		&& v.TIPO_ALOJAMIENTO LIKE(a.TIPO)	
	);

-- update en tabla visita para referenciar viaje -----------------------------------------------------------------------

ALTER TABLE visita ADD cod_viaje VARCHAR(36);

	UPDATE visita vi 
	SET vi.cod_viaje = (
		SELECT v.cod
		FROM viaje v
		WHERE vi.DNI_CLIENTE LIKE(v.DNI_CLIENTE) &&
		vi.NOMBRE_ALOJAMIENTO LIKE(v.NOMBRE_ALOJAMIENTO) &&
		vi.TIPO_ALOJAMIENTO LIKE(v.TIPO_ALOJAMIENTO) &&
		vi.LOCALIDAD_VIAJE LIKE(v.LOCALIDAD) &&
		vi.FECHA_SALIDA_VIAJE LIKE(v.FECHA_SALIDA)
	);
-- update en tabla viaje para codigo cliente --------------------------------------------------------------------------------

ALTER TABLE viaje ADD cod_cliente VARCHAR(36);

	UPDATE viaje v
	SET v.cod_cliente = (
		SELECT c.cod
		FROM cliente c
		WHERE v.DNI_CLIENTE LIKE(c.DNI)	
	);

-- creacion tabla guia -------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TABLE guia(
	cod VARCHAR(36) PRIMARY KEY DEFAULT UUID(),
	DNI VARCHAR(9),
	NOMBRE VARCHAR(20),
	APELLIDO VARCHAR(20),
	FECHA_NAC DATE,
	EMAIL VARCHAR(30),
	TELEFONO INT,
	COD_LOC VARCHAR(36) NOT NULL, -- localidad es foranea
	COD_ATRACCION VARCHAR(36)
);

-- creacion tabla guia_atraccion ---------------------------------------------------------------------------------------------

CREATE OR REPLACE TABLE guia_atraccion(
	cod_guia VARCHAR(36),
	cod_atraccion VARCHAR(36),
	PRIMARY KEY(cod_guia,cod_atraccion)
);

-- restriccion tabla visita --------------------------------------------------------------------------------------------------
-- añadir datos a través de esta vista para comprobar que las fechas de las visitas son correctas ----------------------------

CREATE OR REPLACE VIEW date_checker AS 
SELECT v.cod, v.HORA_INICIO,v.cod_atraccion,v.cod_viaje
FROM visita v JOIN viaje vi ON vi.cod=v.cod_viaje
WHERE v.HORA_INICIO > vi.FECHA_SALIDA && v.HORA_INICIO < vi.FECHA_VUELTA WITH CHECK OPTION;

-- eliminar las columnas que sobran --------------------------------------------------------------------------------------------

ALTER TABLE visita 
	DROP LOCALIDAD_ATRACCION_TURISTICA, 
	DROP NOMBRE_ATRACCION_TURISTICA;

ALTER TABLE atraccion_turistica 
	DROP localidad;

ALTER TABLE alojamiento 
	DROP localidad;

ALTER TABLE viaje 
	DROP NOMBRE_ALOJAMIENTO, 
	DROP TIPO_ALOJAMIENTO,
	DROP localidad,
	DROP dni_cliente;

ALTER TABLE visita
	DROP DNI_CLIENTE,
	DROP NOMBRE_ALOJAMIENTO,
	DROP TIPO_ALOJAMIENTO,
	DROP LOCALIDAD_VIAJE,
	DROP FECHA_SALIDA_VIAJE;

-- claves foraneas -----------------------------------------------------------------------------------------------------------

ALTER TABLE alojamiento 
	ADD CONSTRAINT fk_alo_loc FOREIGN KEY(cod_loc) REFERENCES localidad(cod);

ALTER TABLE atraccion_turistica 
	ADD CONSTRAINT fk_att_loc FOREIGN KEY(cod_loc) REFERENCES localidad(cod);

ALTER TABLE guia 
	ADD CONSTRAINT fk_guia_loc FOREIGN KEY(cod_loc) REFERENCES localidad(COD),
	ADD CONSTRAINT fk_guia_att FOREIGN KEY(cod_atraccion) REFERENCES atraccion_turistica(cod);

ALTER TABLE guia_atraccion 
	ADD CONSTRAINT fk_gui_att_guia FOREIGN KEY(cod_guia) REFERENCES guia(cod),
	ADD CONSTRAINT fk_gui_att_att FOREIGN KEY(cod_atraccion) REFERENCES atraccion_turistica(cod);
	
ALTER TABLE viaje 
	ADD CONSTRAINT fk_vi_loc FOREIGN KEY(cod_loc) REFERENCES localidad(cod),
	ADD CONSTRAINT fk_vi_alo FOREIGN KEY(cod_alojamiento) REFERENCES alojamiento(cod),
	ADD CONSTRAINT fk_vi_tran FOREIGN KEY(cod_transporte) REFERENCES transporte(cod);

ALTER TABLE visita 
	ADD CONSTRAINT fk_vis_att FOREIGN KEY(cod_atraccion) REFERENCES atraccion_turistica(cod),
	ADD CONSTRAINT fk_vis_vi FOREIGN KEY(cod_viaje) REFERENCES viaje(cod);
	
ALTER TABLE localidad 
	ADD CONSTRAINT fk_loc_pre FOREIGN KEY(cod_precio) REFERENCES precio(cod);








