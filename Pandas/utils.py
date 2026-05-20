# Função para categorizar colunas
def tipagem_dados(df, schema):
    import pandas as pd

    for col, tipo in schema.items():
        if tipo == "float":
            df[col] = pd.to_numeric(df[col], errors="coerce")
            
        elif tipo == "int":
              df[col] = pd.to_numeric(df[col], errors="coerce")
            
        elif tipo == "str":
            df[col] = df[col].astype("str")
            
        elif tipo == "datetime":
            df[col] = pd.to_datetime(df[col], errors="coerce")

        elif tipo == "bool":
            df[col] = df[col].astype("bool")

    return df 