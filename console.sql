DROP SCHEMA IF EXISTS project CASCADE;
create schema project;

SET SEARCH_PATH = project;

--3 Create tables
DROP TABLE IF EXISTS project.Campaign CASCADE;
create table project.Campaign
(
    campaign_id   serial primary key,
    campaign_name varchar(90) not null,
    story_book    varchar(200) not null,
    is_done       boolean     not null
);

DROP TABLE IF EXISTS project.Player CASCADE;
create table project.Player
(
    player_id      serial primary key,
    full_name      varchar(50) not null,
    holiday_player boolean     not null
);

DROP TABLE IF EXISTS project.Character CASCADE;
create table project.Character
(
    char_id    serial primary key ,
    player_id  integer REFERENCES project.Player (player_id) ON DELETE CASCADE,
    char_sheet varchar(200) not null
);

DROP TABLE IF EXISTS project.Session CASCADE;
create table project.Session
(
    session_id  serial primary key,
    campaign_id integer not null REFERENCES project.Campaign (campaign_id) ON DELETE CASCADE,
    game_date   date    not null,
    session_num integer not null,
    CONSTRAINT session_num_limit CHECK ( session_num >= 0 )
);


DROP TABLE IF EXISTS project.character_in_session CASCADE;
create table project.character_in_session
(
    char_id    integer not null REFERENCES project.Character (char_id) ON DELETE CASCADE,
    session_id integer not null REFERENCES project.Session (session_id) ON DELETE CASCADE,
    is_npc     boolean not null
);

DROP TABLE IF EXISTS project.player_in_session CASCADE;
create table project.player_in_session
(
    player_id  integer not null REFERENCES project.Player (player_id) ON DELETE CASCADE,
    session_id integer not null REFERENCES project.Session (session_id) ON DELETE CASCADE
);

--4 Filling
COPY project.player FROM '/home/kamil/Experiments/DATA_BASE/PLAYERS' WITH (FORMAT csv);
--add my best friend
INSERT INTO project.player(player_id, full_name, holiday_player) values (40, 'Азат Валеев', TRUE);

COPY project.Campaign FROM '/home/kamil/Experiments/DATA_BASE/Campaigns' WITH (FORMAT csv);
COPY project.Session FROM '/home/kamil/Experiments/DATA_BASE/SESSION' WITH (FORMAT csv);
COPY project.character FROM '/home/kamil/Experiments/DATA_BASE/CHARACTERS' WITH (FORMAT csv);

--add character of my best friend
INSERT INTO project.character(char_id, player_id, char_sheet) values (37 ,(select player_id
                                                               from   project.Player
                                                               where full_name = 'Азат Валеев')
                                                             , 'https://vk.com/doc123633465_602375366'
                                                            );

COPY project.character_in_session FROM '/home/kamil/Experiments/DATA_BASE/CHAR_IN_SESSION' WITH (FORMAT csv);

COPY project.player_in_session FROM '/home/kamil/Experiments/DATA_BASE/PLAYER_SESSION' WITH (FORMAT csv);

--5 Requests

--Игроки-готовые-играть-на-выходных
SELECT Player.full_name as "По выходным играют"
FROM player
where holiday_player = TRUE;

--Кампании-которые-закончили
SELECT camp.campaign_name as "Законченные кампании"
from campaign as camp
where camp.is_done = True;

--Игроки-закончившие-кампанию--
SELECT camp.campaign_name as "Законченная кампания", Player.full_name as "Игрок который прошел кампанию"
from campaign as camp
         inner join session s on camp.campaign_id = s.campaign_id
         inner join player_in_session pis on s.session_id = pis.session_id
         inner join player on pis.player_id = player.player_id
where camp.is_done = True;

--Количество-персонажей-у-каждого-игрока
SELECT player.full_name as player_name, count(c.char_id) as num_of_character
FROM player
inner join character c on Player.player_id = c.player_id
group by player.player_id
order by num_of_character desc;

--Дата-проведения-последней-игры-кампании--
select Campaign.campaign_name as Campaign_name, len_of_session, last_session.date as last_session_was
from (
         Select campaign_id, max(session_num) as len_of_session, max(Session.game_date) as date
         from session
         group by Session.campaign_id
     ) as  last_session,
     campaign
where  Campaign.campaign_id = last_session.campaign_id;

--6 CRUD запросы
--create
 INSERT INTO project.player(player_id, full_name, holiday_player) values (41, 'Александр Халяпов', FALSE);
 INSERT INTO project.character(char_id, player_id, char_sheet) values (38 ,(select player_id
                                                               from   project.Player
                                                               where full_name = 'Александр Халяпов'),
                                                                       'https://dungeon.su/bestiary/440-knight/'
                                                            );
--read
SELECT full_name, char_sheet, holiday_player
FROM player, character
where full_name='Александр Халяпов' and
      Player.player_id = character.player_id;

--update
UPDATE Player
SET holiday_player=TRUE
where full_name = 'Александр Халяпов';

SELECT full_name, char_sheet, holiday_player
FROM player, character
where full_name='Александр Халяпов' and
      Player.player_id = character.player_id;

--delete
DELETE FROM Player WHERE full_name='Александр Халяпов';

--10 выполняя задание на будущее, сделаем функцию, которая будет замазывать поля.

drop function if exists secret_subsuffix(
    secret_text varchar,
    left_bound int,
    shadow_symbol character
);

create function secret_subsuffix(
    secret_text varchar,
    bounds int default 2,
    shadow_symbol character default '*'
) returns varchar as $$
declare

secret_info varchar = '';
input_len int;
n_symbols int;

begin

input_len = char_length(secret_text);

n_symbols = input_len - bounds * 2;


secret_info = repeat(shadow_symbol, n_symbols);
secret_text = overlay(
    secret_text placing secret_info
    from bounds + 1 for n_symbols
);

return secret_text;

end;
$$ language plpgsql;

--7 Создание Views

drop view if exists Players_only_with_id_on_holidays;
create or replace view Players_only_with_id_on_holidays as (
    select secret_subsuffix(full_name)
    from Player
    Where holiday_player = True
);

select powi.*
from Players_only_with_id_on_holidays as powi;

drop view if exists Characters_shadowed_sheets;
create or replace view Characters_shadowed_sheets as (
    select  char_id, player_id, secret_subsuffix(char_sheet, 10)
    from Character
);

select css.*
from Characters_shadowed_sheets as css;

--Названия не законченных кампаний  - секрет
drop view if exists is_not_done_campaign;
create or replace view is_not_done_campaign as (
    select  secret_subsuffix(campaign_name)
    from Campaign
    where is_done = False
    union
    select  campaign_name
    from Campaign
    where is_done = True
);

select indc.*
from is_not_done_campaign as indc;

drop view if exists secret_session;
create or replace view secret_session as (
    select  campaign_name, secret_subsuffix(CAST(Session.game_date as varchar(12)))
    from session
        left join Campaign C on Session.campaign_id = C.campaign_id
    where is_done = False
    union
    select campaign_name, CAST(Session.game_date as varchar(12))
    from session
        left join Campaign C on Session.campaign_id = C.campaign_id
    where is_done = True
);

select ss.*
from secret_session as ss

--8
-- Создайте 2 сложных представления

--Создадим таблицу игроков, которые ходят на сессию, но не имеют персонажей (подразумивается, что они являются GM)
drop view if exists game_masters;
create or replace view game_massters as
(
(select Player.player_id, secret_subsuffix(Player.full_name, 3), Session.session_id, session.session_num
 from session
          inner join character_in_session cis on Session.session_id = cis.session_id and cis.is_npc = False
          inner join character chr on cis.char_id = chr.char_id
          inner join player on chr.player_id = player.player_id)
except
(select Player.player_id, secret_subsuffix(Player.full_name, 3), Session.session_id, session.session_num
from session
         inner join player_in_session pis on Session.session_id = pis.session_id
         inner join player on pis.player_id = player.player_id)

    );

select *
from game_massters
order by game_massters.session_id;

--Сколько игр посетил каждый игрок суммарно
drop view if exists visits;
create or replace view visits as
(
select *
from (select player.full_name, count(Session.session_id)
      from Session
               inner join player_in_session pis on Session.session_id = pis.session_id
               inner join player on pis.player_id = Player.player_id
      group by Player.player_id) as players_visits
order by players_visits.count desc
    );

select *
from visits;

--9 Создание тригеров

INSERT INTO Campaign(campaign_id, campaign_name, is_done, story_book) values (6, 'Welcome Game', FALSE, 'sorry, we will just talk');

--Первый тригер :


drop function if exists hello();
create function hello() returns trigger as $$
begin
    insert into Session(session_id, campaign_id, game_date, session_num)
    values (
            (
            select max(s.session_id) + 1
            from session s
            ),
            6,
            now()::date,
            (
                select coalesce(max(session_num) + 1, 1)
                from session
                where campaign_id = 6
                )
           );

    insert into character_in_session(CHAR_ID, SESSION_ID, IS_NPC)
    values (
            (
                select max(chr.char_id) + 1
                from character chr
            ),(
            select max(s.session_id)
            from session s
            ),
            FALSE
           );

    return new;
end;
$$ language plpgsql;

Create trigger hello_character after insert on Character for row execute procedure hello();

