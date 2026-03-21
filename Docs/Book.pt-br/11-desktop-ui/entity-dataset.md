# Entity DataSet

O **`TEntityDataSet`** é um Dataset em memória de alto desempenho projetado para conectar suas **Listas de Entidades do Dext ORM** diretamente aos componentes visuais tradicionais do Delphi (`TDataSource`, `TDBGrid`, `TDBEdit`) e ferramentas de relatório (como `FastReport` ou `ReportBuilder`).

Em vez de replicar todo o espaço de memória de cada objeto, o **`TEntityDataSet`** usa offsets de memória via os mapas `TEntityMap` do Dext, proporcionando extrema velocidade e zero-allocation.

---

## 🚀 Carregando Dados

Você pode preencher o dataset usando um array de objetos genéricos ou de domínio, ou carregar diretamente de um buffer **JSON ByteSpan** na memória.

### Carregando de uma Lista de Objetos

```pascal
var
  Users: TArray<TUser>;
begin
  Users := Context.Users.ToList; // Busca do Context
  
  DataSet.Load(Users, TUser); // Smart binding
  DataSource.DataSet := DataSet;
end;
```

### Carregando diretamente de um Buffer Utf8 JSON

```pascal
var
  JsonBytes: TBytes;
  Span: TByteSpan;
begin
  JsonBytes := TEncoding.UTF8.GetBytes(Payload);
  Span := TByteSpan.Create(JsonBytes);

  DataSet.LoadFromUtf8Json(Span, TUser);
end;
```

---

## 🔍 Filtros e Buscas

O dataset gerencia a ordenação e filtragem puramente em memória usando o framework de queries eficientes do Dext.

### Filtragem por Expressão

Você pode setar filtros nativamente usando tokens clássicos de String:

```pascal
DataSet.Filter := 'Score > 100';
DataSet.Filtered := True;
```

### Buscas Rápidas (Lookup)

```pascal
if DataSet.Locate('Name', 'Cesar', []) then
  ShowMessage('Encontrado!');
```

---

## 🏆 Recursos Principais

- **Zero Allocation na Carga de Valores:** A leitura de valores é vinculada a offsets de forma otimizada.
- **DML Memory Mode:** Append, Edit e Delete operacionais dentro da estrutura.
- **Preparado para Component Palette:** Suporte para design-time e sincronização de `TFields` persistentes.
