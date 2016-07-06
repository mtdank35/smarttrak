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
    public class ProdTypeRepo
    {
        private IDatabase _db;
        public ProdTypeRepo(IDatabase db)
        {
            _db = db;
        }

        public ProdType Get(string code, SqlTransaction tx = null)
        {
            // someday, map appropriate primary keys to the db table and get them into the classmapper so dapper will automatically figure them out
            var entity = _db.Connection.Query<ProdType>("SELECT * FROM ProdType WHERE code=@p1", new { p1 = code }, tx).FirstOrDefault();
            return entity;
        }

        public List<ProdType> GetList(IPredicate pred = null, SqlTransaction tx = null)
        {
            return _db.Connection.GetList<ProdType>(pred, null, tx).OrderBy(x=>x.descrip).ToList();
        }

        public void Insert(ProdType entity, SqlTransaction tx = null)
        {
            _db.Insert(entity, tx);
        }

        public bool Update(ProdType entity, SqlTransaction tx = null)
        {
            return _db.Update(entity, tx);
        }

        public void Upsert(ProdType entity, SqlTransaction tx = null)
        {
            if (!Update(entity, tx))
                Insert(entity, tx);
        }

        public void Delete(ProdType entity, SqlTransaction tx = null)
        {
            _db.Delete(entity, tx);
        }
    }
}
