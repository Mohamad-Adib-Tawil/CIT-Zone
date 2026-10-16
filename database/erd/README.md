# مخططات ERD المحلية

تولد من `../schema.sql` عبر `python3 database/build.py`. الحقول والعلاقات من SQL مع أعمدة ALTER؛ أطراف العلاقة مشتقة من NULL/PRIMARY KEY/UNIQUE، ولا تستبدل القيود الجزئية أو منطق Trigger في SQL. توجد علاقات بين الوحدات في المخطط الكامل.

- [كامل مع الحقول](full.mmd)
- [كل العلاقات](relationships.mmd)
- [A-identity](A-identity.md): 9 tables
- [B-academic](B-academic.md): 6 tables
- [C-content](C-content.md): 15 tables
- [D-exercises](D-exercises.md): 8 tables
- [E-offline](E-offline.md): 8 tables
- [F-commerce](F-commerce.md): 14 tables
- [G-grades](G-grades.md): 7 tables
- [H-communication](H-communication.md): 8 tables
- [I-system](I-system.md): 5 tables
