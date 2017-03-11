CREATE TRIGGER create_user_status_on_user_creation AFTER INSERT ON users
BEGIN
	INSERT INTO user_status (user, status)
	values (NEW.id, 0);
END;