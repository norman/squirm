# Squirm

Squirm is a database library that facilitates working with Postgres and stored
procedures.

## About

Squirm is not stable yet. Feel free to play around with it, but unless you want
to contribute to its development, you probably shouldn't use it for anything
sensitive.

It currently provides:

* A basic connection pool
* A little syntactic sugar around the pg gem
* Class for accessing stored procedures as if they were Ruby procs

Here's a quick demo of how you might use it:

    -- Your database
    CREATE TABLE "users" (
      "name"  VARCHAR(256),
      "email" VARCHAR(64) NOT NULL UNIQUE
    );

    CREATE SCHEMA "users";

    CREATE FUNCTION "users"."create"(_email text, _name text) RETURNS integer AS $$
      DECLARE
        new_id integer;
      BEGIN
        INSERT INTO "users" (email, name) VALUES (_email, _name)
          RETURNING id INTO new_id;
        IF FOUND THEN
          RETURN new_id;
        END IF;
      END;
    $$ LANGUAGE 'plpgsql';

    Squirm.connect dbname: "your_database"
    create = Squirm::Procedure.new("create", schema: "users")
    id = create.call(email: "johndoe@example.com", name: "John Doe")

In and of itself, Squirm offers very little, but is meant to be a basic building
block for other libraries, such as [Squirm
Model](https://github.com/bvision/squirm_model), which supplies an Active Model
compatible ORM based on stored procedures.

## Using it with Rails

Squirm comes with built-in support to make it work seamlessly with Active Record:

    class Person < ActiveRecord::Base
      procedure :say_hello
    end
    
    p = Person.find(23)
    p.say_hello

More documentation coming soon.

## Author

Norman Clarke <nclarke@bvision.com>

## License

Copyright (c) 2011 Norman Clarke and Business Vision S.A.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
