using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using Dapper;
using DapperExtensions;
using Basf.Data.Tables;
using DapperExtensions.Sql;
using DapperExtensions.Mapper;
using System.Reflection;

namespace Basf.Data.Repos
{
    public class ShadesRepo
    {
        private IDatabase _db;
        public ShadesRepo(IDatabase db)
        {
            _db = db;
        }

        public Shades Get(string shadeVal, SqlTransaction tx = null)
        {
            // someday, map appropriate primary keys to the db table and get them into the classmapper so dapper will automatically figure them out
            var entity = _db.Connection.Query<Shades>("SELECT * FROM Shades WHERE tval_shade=@p1", new { p1 = shadeVal }, tx).FirstOrDefault();
            return entity;
        }

        public List<Shades> GetList(IPredicate pred = null, SqlTransaction tx = null)
        {
            return _db.Connection.GetList<Shades>(pred, null, tx).OrderBy(x=>x.shadedesc).ToList();
        }

        public void Insert(Shades entity, SqlTransaction tx = null)
        {
            _db.Insert(entity, tx);
        }

        public bool Update(Shades entity, SqlTransaction tx = null)
        {
            return _db.Update(entity, tx);
        }

        public void Upsert(Shades entity, SqlTransaction tx = null)
        {
            if (!Update(entity, tx))
                Insert(entity, tx);
        }

        public void Delete(Shades entity, SqlTransaction tx = null)
        {
            _db.Delete(entity, tx);
        }
    }
}
