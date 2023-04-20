CREATE TABLE musicians
(
    id int not null,
    name VARCHAR NOT null ,
    date int not null,
    CONSTRAINT music_pk PRIMARY KEY (id)
);

CREATE TABLE groupss 
(
  	id int not null,
    name VARCHAR NOT null ,
    date int not null,
    CONSTRAINT grp_pk PRIMARY KEY (id)
);

CREATE TABLE v_sostave 
(
    date_p int not null,
    id_m int NOT null ,
    id_g int not null,    
    CONSTRAINT FK_musicians FOREIGN KEY (id_m) 
        REFERENCES musicians (id) ON DELETE CASCADE,
    CONSTRAINT FK_groupss FOREIGN KEY (id_g) 
        REFERENCES groupss (id) ON DELETE CASCADE
);

insert into musicians values(1,'Tom',1968),(2,'Julian',1978),(3,'Jonny',1971), (4,'Julian',1980);
insert into musicians values (5,'Julian',1980);
insert into groupss values(1,'Radiohead',1985),(2,'Voidz',2013),(3,'The Smile',2021),(4,'The Smile',2021),(5,'The Strokes',1998);
insert into v_sostave values(1985,1,1),(1985,3,1),(2021,1,3),(2021,3,3),(2013,2,2),(1998,2,5);
insert into v_sostave values(2020,5,1)

--Представление таблиц
CREATE OR REPLACE VIEW full_view AS
SELECT vs.date_p AS dateSostava, 
	   m.name AS musicianName,
	   m.date AS byearMusician,
	   g.name AS groupName,
	   g.date AS oyearGroup
FROM v_sostave vs 
	 JOIN musicians m ON vs.id_m  = m.id 
     JOIN groupss g ON vs.id_g  = g.id;

select * from full_view
order by datesostava;

--Триггер для добавления
CREATE OR REPLACE FUNCTION insert_full() RETURNS trigger AS
$$
DECLARE
  _id_m integer;
  _id_g integer;
  _id_s integer;
BEGIN
  SELECT id FROM musicians WHERE name = NEW.musicianName AND date = NEW.byearMusician INTO _id_m;
  SELECT id FROM groupss WHERE name = NEW.groupName AND date = NEW.oyearGroup INTO _id_g;
  IF (_id_m IS NULL) then
  SELECT MAX(id)+1 FROM musicians m  INTO _id_m;
  	INSERT INTO musicians(id,name,date) VALUES (_id_m,NEW.musicianName, NEW.byearMusician); 
  END IF;
  IF (_id_g IS NULL) then
  SELECT MAX(id)+1 FROM groupss INTO _id_g;
  	INSERT INTO groupss(id,name, date) VALUES (_id_g, NEW.groupName, NEW.oyearGroup); 
  END IF;
  SELECT date_p FROM v_sostave WHERE id_m = _id_m AND id_g = _id_g INTO _id_s;
  IF (_id_s IS NULL) then
  INSERT INTO v_sostave (date_p, id_m,id_g)
  VALUES (NEW.dateSostava, _id_m, _id_g);
  END IF;
 return OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_full_trigger
  instead of INSERT
  ON full_view
  FOR EACH ROW
EXECUTE PROCEDURE insert_full();

-- Триггер для изменения
CREATE OR REPLACE FUNCTION update_full() RETURNS trigger AS
$$
DECLARE
  _id_m integer;
  _id_g integer;
begin
	IF NEW.dateSostava IS NOT NULL 
	then
	UPDATE v_sostave vs SET date_p = NEW.dateSostava
	from musicians m,groupss g
	where vs.id_m=m.id and vs.id_g=g.id AND (vs.date_p = OLD.dateSostava OR 
  	(m.name,m.date,g.name,g.date) 
	 IN(select m.name,m.date,g.name,g.date FROM v_sostave vs
     	JOIN musicians m ON vs.id_m = m.id
     	JOIN groupss g ON vs.id_g = g.id
     	WHERE m.name = NEW.musicianName AND
     		m.date = NEW.byearMusician AND
     		g.name = NEW.groupName AND
     	    g.date = NEW.oyearGroup)
     );
  	END IF;
 
  SELECT id FROM musicians WHERE name = NEW.musicianName AND date = NEW.byearMusician INTO _id_m;
  SELECT id FROM groupss WHERE name = NEW.groupName AND date = NEW.oyearGroup INTO _id_g;
 
  IF (_id_m IS NOT NULL AND _id_g IS NOT NULL) THEN
 	UPDATE v_sostave vs SET id_m = _id_m, id_g = _id_g
    WHERE vs.date_p = NEW.dateSostava; 
   
  elseiF (_id_g IS NOT NULL) THEN 
  	UPDATE v_sostave vs SET id_g = _id_g
    WHERE vs.date_p = NEW.dateSostava;  
  elseIF (_id_m IS NOT NULL) THEN
  	UPDATE v_sostave vs SET id_m = _id_m
    WHERE vs.date_p = NEW.dateSostava; 
   
  END IF;
 RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_full_trigger
  INSTEAD OF UPDATE
  ON full_view
  FOR EACH ROW
EXECUTE PROCEDURE update_full();

--Триггер для удаления
CREATE OR REPLACE FUNCTION delete_full() RETURNS trigger AS
$$
DECLARE
  _id_m integer;
  _id_g integer;
begin
  SELECT id FROM musicians WHERE name = OLD.musicianName AND date = OLD.byearMusician INTO _id_m;
  SELECT id FROM groupss WHERE name = OLD.groupName AND date = OLD.oyearGroup INTO _id_g;
 DELETE FROM v_sostave WHERE 
 date_p = OLD.dateSostava AND id_m= _id_m and id_g = _id_g;
 IF NOT FOUND THEN RETURN NULL;
 END IF;
 RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_full_trigger
  INSTEAD OF DELETE
  ON full_view
  FOR EACH ROW
EXECUTE PROCEDURE delete_full();

--Тесты
--Добавление(новый музыкант) 
INSERT INTO full_view VALUES
(2020, 'Julian', 1980, 'Radiohead', 1985);
SELECT * FROM musicians; -- добавлена информация о новом музыканте
SELECT * from v_sostave; --добавлена информация новой связи
SELECT * FROM full_view
order by musicianName;

--Изменение(данные о группе и дате состава)
UPDATE full_view SET datesostava = 2000, groupname = 'Radiohead', oyeargroup=1985
WHERE 
dateSostava = 2021 and
musicianname = 'Tom' AND 
byearmusician = 1968 AND 
groupname = 'The Smile' AND
oyeargroup = 2021;

SELECT * FROM full_view
order by musicianName;

select * from v_sostave vs ;
--Изменение(данные о группе)
UPDATE full_view SET groupname = 'Voidz', oyeargroup=1990
WHERE datesostava = 2000;

SELECT * FROM full_view
order by musicianName;

select * from v_sostave vs;
--Удаление
DELETE FROM full_view WHERE groupName = 'Radiohead';

select * from v_sostave vs ;

SELECT * FROM full_view
order by datesostava;

DELETE FROM full_view WHERE groupName = 'Radiohead' AND musicianName = 'Jonny';

select * from v_sostave vs;
--Поиск
Select g.name as groupss, m.name as musician, v.date_p as dataSostava
FROM musicians m
JOIN v_sostave v on v.id_m = m.id
JOIN groupss g on g.id = v.id_g
order by groupss, musician, dataSostava;

select * from full_view
WHERE 
musicianName = 'Tom' AND 
byearMusician = 1968 AND 
groupName = 'The Smile' AND
oyearGroup = 2021;

select distinct g.name as gr, m.name as musician from v_sostave v
join groupss g on g.id = v.id_g
join musicians m on m.id = v.id_m
where g.name = 'Radiohead' and v.date_p <= 2000;

drop view if exists full_view;
drop table if exists v_sostave;
drop table if exists musicians;
drop table if exists groupss;
DROP FUNCTION IF EXISTS insert_full();
DROP FUNCTION IF EXISTS update_full();
DROP FUNCTION IF EXISTS delete_full();