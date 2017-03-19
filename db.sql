USE daheim;
CREATE TABLE users(
id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(20),
uuid VARCHAR(80),
home INT,
FOREIGN KEY(home) references home(id));
CREATE TABLE user_status(
	id integer primary key AUTO_INCREMENT,
	user integer,
	status integer,
	expires_at datetime,
	create_date datetime default current_timestamp,
	foreign key(user) references users(id)
);
CREATE TRIGGER create_user_status_on_user_creation AFTER INSERT ON users
BEGIN
	INSERT INTO user_status (user, status)
	values (NEW.id, 0);
END;
CREATE VIEW v_user_status as
select u.*, s.status from v_actual_status s
join users u on s.user = u.id;
CREATE VIEW v_user_per_home as select u.id as user, h.id as home from users u join homes h on u.home = h.id;
CREATE VIEW v_user_home_status AS 
SELECT U.ID AS USER, H.ID AS HOME, U.NAME AS NAME, s.STATUS AS STATUS 
FROM USERS U 
JOIN HOMES H ON U.HOME = H.ID
JOIN v_actual_status s on s.user = u.id;
CREATE VIEW v_home_detail as select h.id, h.bssid as bssid, h.name as name, (select count(*) from v_user_per_home where home = h.id) as user from homes h;
CREATE VIEW v_actual_status as
SELECT user, status, max(create_date) as create_date from user_status
where expires_at > datetime('now') or expires_at is null
group by user;
