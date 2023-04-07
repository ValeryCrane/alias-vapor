CREATE TABLE "users" (
                         "id" uuid PRIMARY KEY,
                         "username" varchar,
                         "password" varchar
);

CREATE TABLE "tokens" (
                          "id" uuid PRIMARY KEY,
                          "token" varchar,
                          "user_id" uuid
);

ALTER TABLE "tokens" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id");
