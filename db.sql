BEGIN TRANSACTION;
CREATE TABLE users(
id INTEGER PRIMARY KEY AUTOINCREMENT,
name TEXT,
uuid TEXT,
home INTEGER,
FOREIGN KEY(home) references home(id));
CREATE TABLE user_status(
	id integer primary key autoincrement,
	user integer,
	status integer,
	expires_at datetime,
	create_date datetime default current_timestamp,
	foreign key(user) references users(id)
);
CREATE TABLE homes(
id integer primary key autoincrement,
name TEXT,
bssid TEXT);
CREATE VIEW v_user_status as
select u.id as id, u.home as home, u.name as name, u.uuid as uuid, s.status  as status from v_actual_status s
join users u on u.id = s.user;
CREATE VIEW v_user_per_home as select u.id as user, h.id as home from users u join homes h on u.home = h.id;
CREATE VIEW v_user_home_status AS 
SELECT U.ID AS USER, H.ID AS HOME, U.NAME AS NAME, s.STATUS AS STATUS 
FROM USERS U 
JOIN HOMES H ON U.HOME = H.ID
JOIN v_actual_status s on s.user = u.id;
CREATE VIEW v_home_detail as select h.id, h.bssid as bssid, h.name as name, (select count(*) from v_user_per_home where home = h.id) as user from homes h;
CREATE VIEW v_actual_status as
 select user, status from user_status
 where create_date = (select max(create_date) from user_status where expires_at > date('now'));
COMMIT;
