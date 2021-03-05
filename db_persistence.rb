require "pg"

class DB
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname:"db230")
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def get(table_name, params) 
    sql = "SELECT * FROM $1 WHERE id=$2"
    result = query(sql, table_name, params[:id])

    result.map do |tuple|
      {
        id: tuple["id"],
        username: tuple["username"],
        bio: tuple["bio"],
        password: tuple["password"]
      }
    end
  end

  def add(table_name, params)
    sql = "INSERT INTO $1 VALUES (DEFAULT, $2, $3)"
    if table_name == "posts"
      query(sql, table_name, params[:content], params[:user_id])
    elsif table_name == "comments"
      query(sql, table_name, params[:content], params[:post_id])
    end
  end

  def remove(table_name, id)
    sql = "DELETE FROM $1 VALUES WHERE id = $2"
    query(sql, table_name, id)
  end
end