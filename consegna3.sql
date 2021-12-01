DROP DATABASE IF EXISTS FIERA_INFORMATICA;
CREATE DATABASE IF NOT EXISTS FIERA_INFORMATICA;
USE FIERA_INFORMATICA;

CREATE TABLE EDIZIONE (
	Anno INT PRIMARY KEY,
    Titolo VARCHAR(20),
    Data_Inizio DATE,
    Data_Fine DATE,
    Numero_Stand INT DEFAULT 0,
    CHECK (Data_Inizio < Data_Fine)
) ENGINE=INNODB;

CREATE TABLE SPONSOR ( 
	Nome VARCHAR(15) PRIMARY KEY,
    Logo VARCHAR(10),
    Tipologia ENUM("BRONZE", "SILVER", "GOLD") DEFAULT "BRONZE"
) ENGINE=INNODB;

CREATE TABLE SPONSORIZZAZIONE (
	Nome_Sponsor VARCHAR(15), 
    Anno_Edizione INT,
    PRIMARY KEY ( Nome_Sponsor, Anno_Edizione ),
    FOREIGN KEY ( Nome_Sponsor ) REFERENCES SPONSOR ( Nome ) ON DELETE CASCADE, 
	FOREIGN KEY ( Anno_Edizione ) REFERENCES EDIZIONE ( Anno ) ON DELETE CASCADE
) ENGINE=INNODB;

CREATE TABLE PADIGLIONE (
	Numero INT PRIMARY KEY,
    Metratura DOUBLE,
    Piantina VARCHAR(30)
) ENGINE=INNODB;

CREATE TABLE STAND (
	Numero INT,
    Anno_Edizione INT,
    Descrizione VARCHAR(30),
    Numero_Padiglione INT,
    PRIMARY KEY ( Numero, Anno_Edizione ),
	FOREIGN KEY ( Anno_Edizione ) REFERENCES EDIZIONE ( Anno ),
    FOREIGN KEY ( Numero_Padiglione ) REFERENCES PADIGLIONE ( Numero )
) ENGINE=INNODB;

CREATE TABLE ESPOSITORE ( 
	CF VARCHAR(20) PRIMARY KEY,
    EMail VARCHAR(20),
    Stand INT,
    Anno_Edizione INT,
	FOREIGN KEY ( Stand, Anno_Edizione ) REFERENCES STAND ( Numero, Anno_Edizione )
) ENGINE=INNODB; 

CREATE TABLE BIGLIETTO (
	Numero INT,
    Anno_Edizione INT,
    Costo DOUBLE,
    Data_Emissione DATE,
    Data_Accesso DATE,
    PRIMARY KEY ( Numero, Anno_Edizione ),
    FOREIGN KEY ( Anno_Edizione ) REFERENCES EDIZIONE ( Anno )
) ENGINE=INNODB;

CREATE TABLE PASS_NOMINATIVO (
	Nome VARCHAR(15),
    Cognome VARCHAR(15),
    Data_Nascita DATE,
    Numero_Biglietto INT,
    Anno_Edizione INT,
    PRIMARY KEY( Nome, Cognome, Data_Nascita, Numero_Biglietto ),
	FOREIGN KEY ( Numero_Biglietto, Anno_Edizione ) REFERENCES BIGLIETTO ( Numero, Anno_Edizione ) ON DELETE CASCADE
) ENGINE=INNODB;

CREATE TABLE PREFERENZA ( 
	Nome VARCHAR(15),
    Cognome VARCHAR(15),
	Data_Nascita DATE,
    Numero_Biglietto INT,
    CF_Espositore VARCHAR(30),
    Punteggio INT CHECK (Punteggio >= 0 AND Punteggio <= 10),
    Testo VARCHAR(200),
    PRIMARY KEY( Numero_Biglietto, CF_Espositore ),
    FOREIGN KEY ( Nome, Cognome, Data_Nascita ) REFERENCES PASS_NOMINATIVO ( Nome, Cognome, Data_Nascita ),
    FOREIGN KEY ( CF_Espositore ) REFERENCES ESPOSITORE( CF )
) ENGINE=INNODB;

CREATE TABLE AZIENDA(
	CF_Espositore VARCHAR(30),
    PIVa VARCHAR(30),
    Indirizzo VARCHAR(20),
    Nome VARCHAR(15),
    PRIMARY KEY (CF_Espositore),
    FOREIGN KEY (CF_Espositore) REFERENCES ESPOSITORE (CF)
) ENGINE=INNODB;

CREATE TABLE ACCADEMIA(
	CF_Espositore VARCHAR(30),
    Nome_Uni VARCHAR(30),
    Dipartimento VARCHAR(20),
    PRIMARY KEY (CF_Espositore),
    FOREIGN KEY (CF_Espositore) REFERENCES ESPOSITORE (CF)
) ENGINE=INNODB;

CREATE TABLE DOCENTE(
	Nome VARCHAR(15),
    CF_Espositore VARCHAR(30),
    PRIMARY KEY (Nome,CF_Espositore),
    FOREIGN KEY (CF_Espositore) REFERENCES ACCADEMIA (CF_Espositore)
)ENGINE=INNODB;

CREATE TABLE FOTO(
	Codice VARCHAR(10),
    CF_Espositore VARCHAR(30),
    Dimensione DOUBLE,
    Formato VARCHAR(10),
    PRIMARY KEY (Codice, CF_Espositore),
    FOREIGN KEY (CF_Espositore) REFERENCES AZIENDA (CF_Espositore)
)ENGINE=INNODB;

CREATE TABLE WORKSHOP(
	Titolo VARCHAR(20),
    Data DATE,
    Orario DATE,
    PRIMARY KEY(Titolo, Data)
) ENGINE=INNODB;

CREATE TABLE REGISTRAZIONE(
	Numero_Biglietto INT ,
    Anno_Edizione INT,
    Titolo_Workshop VARCHAR(20),
    Data_Workshop DATE,
    PRIMARY KEY(Numero_Biglietto, Anno_Edizione, Titolo_Workshop, Data_Workshop),
    FOREIGN KEY (Numero_Biglietto, Anno_Edizione) REFERENCES BIGLIETTO (Numero, Anno_Edizione),
	FOREIGN KEY (Titolo_Workshop, Data_Workshop) REFERENCES WORKSHOP (Titolo, Data)
) ENGINE=INNODB;

CREATE TABLE ORGANIZZAZIONE(
	CF_Accademia VARCHAR(30),
    Titolo_Workshop VARCHAR(20),
    Data_Workshop DATE,
    PRIMARY KEY(CF_Accademia, Titolo_Workshop, Data_Workshop),
	FOREIGN KEY (CF_Accademia) REFERENCES ACCADEMIA (CF_Espositore),
	FOREIGN KEY (Titolo_Workshop, Data_Workshop) REFERENCES WORKSHOP (Titolo, Data)
) ENGINE=INNODB;

################################
####### STORED PROCEDURES ######
################################

DELIMITER $
CREATE PROCEDURE ContaStand
(IN AnnoIN INT)
BEGIN 
	START TRANSACTION;
		IF( (AnnoIN = ANY (SELECT Anno FROM EDIZIONE))) THEN
				SELECT COUNT(*) AS NumeroStand FROM STAND WHERE STAND.Anno_Edizione = AnnoIN;
        ELSE 
			SELECT CONCAT("NO NERDS PARTY IN THAT YEAR") AS MESSAGE;
		END IF;
    COMMIT WORK;
END ;
$ DELIMITER ;

DELIMITER $
CREATE PROCEDURE VisualizzaDatiEdizioneStand
()
BEGIN 
	START TRANSACTION;
		SELECT Anno, Titolo, Data_Inizio, Data_Fine, Numero_Stand, STAND.Numero AS ID_Stand, Descrizione, Numero_Padiglione 
        FROM EDIZIONE, STAND 
        WHERE EDIZIONE.Anno = STAND.Anno_Edizione;
    COMMIT WORK;
END ;
$ DELIMITER ;

DELIMITER $
CREATE PROCEDURE CreaStand
(IN NumeroIN INT, IN AnnoIN INT, IN Descrizione VARCHAR(30), IN Numero_Padiglione INT)
BEGIN 
	START TRANSACTION;
		IF( AnnoIN = ANY(SELECT Anno_Edizione FROM STAND) AND NumeroIN NOT IN (SELECT Numero FROM STAND) AND Numero_Padiglione IN (SELECT Numero FROM PADIGLIONE)) THEN
			INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione) VALUES (NumeroIN, AnnoIN, Descrizione, Numero_Padiglione);
		ELSE
			SELECT CONCAT("MMHH A PROBLEM OCCURED") AS MESSAGE;
        END IF;
    COMMIT WORK;
END ;
$ DELIMITER ;      

DELIMITER $
CREATE PROCEDURE RimuoviSponsor
(IN AnnoIN INT)
BEGIN 
	START TRANSACTION;
        SET SQL_SAFE_UPDATES=0;
        DELETE SPONSOR, SPONSORIZZAZIONE
		FROM SPONSOR
		INNER JOIN SPONSORIZZAZIONE ON SPONSOR.Nome = SPONSORIZZAZIONE.Nome_Sponsor
		WHERE SPONSORIZZAZIONE.Anno_Edizione = AnnoIN;
        
        # It will probably return 0 rows affected but it actually deletes...
        
	COMMIT WORK;
END ;
$ DELIMITER ;

DELIMITER $
CREATE TRIGGER IncrementaNumeroStand
AFTER INSERT ON STAND
FOR EACH ROW BEGIN
	UPDATE EDIZIONE SET Numero_Stand = Numero_Stand + 1 WHERE NEW.Anno_Edizione = Anno;
END;
$ DELIMITER ;

INSERT INTO EDIZIONE(Anno, Titolo, Data_Fine) VALUES (2021, "BIT A BIT", Now());
INSERT INTO EDIZIONE(Anno, Titolo, Data_Fine) VALUES (2020, "L-ASCII STARE", Now());
INSERT INTO EDIZIONE(Anno, Titolo, Data_Fine) VALUES (2019, "1+1 = 10", Now());

INSERT INTO PADIGLIONE(Numero, Metratura, Piantina) VALUES (1, 100, "aaa");
INSERT INTO PADIGLIONE(Numero, Metratura, Piantina) VALUES (2, 200, "bbb");
INSERT INTO PADIGLIONE(Numero, Metratura, Piantina) VALUES (3, 300, "ccc");
INSERT INTO PADIGLIONE(Numero, Metratura, Piantina) VALUES (4, 400, "ddd");
INSERT INTO PADIGLIONE(Numero, Metratura, Piantina) VALUES (5, 500, "eee");

INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione ) VALUES (1, 2021, "Bello", 1);
INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione ) VALUES (2, 2021, "si", 1);
INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione ) VALUES (3, 2021, "eh", 1);
INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione ) VALUES (4, 2021, "ok", 1);
INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione ) VALUES (5, 2021, "mah", 1);

INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione ) VALUES (1, 2019, "Bello", 2);
INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione ) VALUES (2, 2020, "si", 3);
INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione ) VALUES (3, 2020, "eh", 4);
INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione ) VALUES (4, 2019, "ok", 1);
INSERT INTO STAND(Numero, Anno_Edizione, Descrizione, Numero_Padiglione ) VALUES (5, 2019, "mah", 3);

INSERT INTO SPONSOR(Nome, Logo, Tipologia) VALUES ("ACS SOFTWARE", "AA", "SILVER");
INSERT INTO SPONSOR(Nome, Logo, Tipologia) VALUES ("CC COMPUTER", "CC", "BRONZE");
INSERT INTO SPONSOR(Nome, Logo, Tipologia) VALUES ("M-LEARNING", "ML", "GOLD");

INSERT INTO SPONSORIZZAZIONE(Nome_Sponsor, Anno_Edizione) VALUES ("ACS SOFTWARE", 2021);
INSERT INTO SPONSORIZZAZIONE(Nome_Sponsor, Anno_Edizione) VALUES ("CC COMPUTER", 2021);
INSERT INTO SPONSORIZZAZIONE(Nome_Sponsor, Anno_Edizione) VALUES ("M-LEARNING", 2020)


