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
    public class ColorTypesRepo
    {
        private IDatabase _db;
        public ColorTypesRepo(IDatabase db)
        {
            _db = db;
        }

        public ColorTypes Get(string type, SqlTransaction tx = null)
        {
            // someday, map appropriate primary keys to the db table and get them into the classmapper so dapper will automatically figure them out
            var entity = _db.Connection.Query<ColorTypes>("SELECT * FROM colortypes WHERE colortype=@p1", new { p1 = type }, tx).FirstOrDefault();
            return entity;
        }

        public List<ColorTypes> GetList(IPredicate pred = null, SqlTransaction tx = null)
        {
            return _db.Connection.GetList<ColorTypes>(pred, null, tx).OrderBy(x=>x.typedesc).ToList();
        }

        public void Insert(ColorTypes entity, SqlTransaction tx = null)
        {
            _db.Insert(entity, tx);
        }

        public bool Update(ColorTypes entity, SqlTransaction tx = null)
        {
            return _db.Update(entity, tx);
        }

        public void Upsert(ColorTypes entity, SqlTransaction tx = null)
        {
            if (!Update(entity, tx))
                Insert(entity, tx);
        }

        public void Delete(ColorTypes entity, SqlTransaction tx = null)
        {
            _db.Delete(entity, tx);
        }
    }
}
