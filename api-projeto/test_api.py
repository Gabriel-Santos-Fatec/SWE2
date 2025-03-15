import requests
from fastapi import FastAPI

app = FastAPI()

BASE_URL = "http://localhost:4000"

@app.get("/")
def read_root():
    return {"message": "Test API for Node.js endpoints"}

# Testes para Engenheiros
@app.post("/test/engenheiros")
def test_create_engenheiro():
    data = {"nome": "João", "cargaMaxima": 10, "eficiencia": 0.9}
    response = requests.post(f"{BASE_URL}/engenheiros", json=data)
    return {"status_code": response.status_code, "response": response.json()}

@app.get("/test/engenheiros")
def test_get_engenheiros():
    response = requests.get(f"{BASE_URL}/engenheiros")
    return {"status_code": response.status_code, "response": response.json()}

@app.put("/test/engenheiros/{id}")
def test_update_engenheiro(id: int):
    data = {"nome": "João Atualizado", "cargaMaxima": 12, "eficiencia": 0.95}
    response = requests.put(f"{BASE_URL}/engenheiros/{id}", json=data)
    return {"status_code": response.status_code, "response": response.json()}

@app.delete("/test/engenheiros/{id}")
def test_delete_engenheiro(id: int):
    response = requests.delete(f"{BASE_URL}/engenheiros/{id}")
    return {"status_code": response.status_code, "response": response.json()}

# Testes para Tarefas
@app.post("/test/tarefas")
def test_create_tarefa():
    data = {
        "nome": "Nova Tarefa",
        "prioridade": "Alta",
        "tempo": 120,
        "status": "Pendente",
        "idEngenheiro": None
    }
    response = requests.post(f"{BASE_URL}/tarefas", json=data)
    return {"status_code": response.status_code, "response": response.json()}

@app.get("/test/tarefas")
def test_get_tarefas():
    response = requests.get(f"{BASE_URL}/tarefas")
    return {"status_code": response.status_code, "response": response.json()}

@app.put("/test/tarefas/{id}")
def test_update_tarefa(id: int):
    data = {
        "nome": "Tarefa Atualizada",
        "prioridade": "Média",
        "tempo": 100,
        "status": "Em andamento",
        "idEngenheiro": 1 
    }
    response = requests.put(f"{BASE_URL}/tarefas/{id}", json=data)
    return {"status_code": response.status_code, "response": response.json()}

@app.delete("/test/tarefas/{id}")
def test_delete_tarefa(id: int):
    response = requests.delete(f"{BASE_URL}/tarefas/{id}")
    return {"status_code": response.status_code, "response": response.json()}

@app.post("/test/tarefas/alocar")
def test_alocar_tarefas():
    response = requests.post(f"{BASE_URL}/tarefas/alocar")

    print(f"Resposta bruta da API: {response.text}")  # Exibir resposta antes de converter

    try:
        return {"status_code": response.status_code, "response": response.json()}
    except requests.exceptions.JSONDecodeError:
        return {"status_code": response.status_code, "response": "Resposta inválida ou vazia"}

@app.put("/test/tarefas/{id}/iniciar")
def test_iniciar_tarefa(id: int):
    response = requests.put(f"{BASE_URL}/tarefas/{id}/iniciar")
    return {"status_code": response.status_code, "response": response.json()}

@app.put("/test/tarefas/{id}/pausar")
def test_pausar_tarefa(id: int):
    response = requests.put(f"{BASE_URL}/tarefas/{id}/pausar")
    return {"status_code": response.status_code, "response": response.json()}

@app.put("/test/tarefas/{id}/concluir")
def test_concluir_tarefa(id: int):
    response = requests.put(f"{BASE_URL}/tarefas/{id}/concluir")
    return {"status_code": response.status_code, "response": response.json()}



# Iniciar o servidor FastAPI
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000, reload=True)
