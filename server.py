import sys
import json
import urllib.request
import urllib.parse
import os

# Configuración base
JOPLIN_TOKEN = os.environ.get("JOPLIN_TOKEN")
JOPLIN_PORT = os.environ.get("JOPLIN_PORT", "41184")
BASE_URL = f"http://localhost:{JOPLIN_PORT}"

def joplin_request(endpoint, query_params=None, method="GET", data=None):
    if not JOPLIN_TOKEN:
        sys.stderr.write("WARNING: JOPLIN_TOKEN is empty or not set\n")

    if query_params is None:
        query_params = {}
    query_params['token'] = JOPLIN_TOKEN

    query_string = urllib.parse.urlencode(query_params)
    url = f"{BASE_URL}/{endpoint}?{query_string}"
    sys.stderr.write(
        f"DEBUG: {method} {BASE_URL}/{endpoint} (token length: {len(JOPLIN_TOKEN) if JOPLIN_TOKEN else 0})\n"
    )

    try:
        headers = {}
        payload = None

        if data is not None:
            payload = json.dumps(data).encode('utf-8')
            headers['Content-Type'] = 'application/json'

        req = urllib.request.Request(url, data=payload, headers=headers, method=method)
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data
    except Exception as e:
        return {"error": str(e)}

def search_notes(query):
    data = joplin_request("search", {"query": query})
    if "error" in data:
        return f"Error: {data['error']}"
    
    items = data.get("items", [])
    if not items:
        return "No se encontraron notas."
    
    results = [f"- {item['title']} (ID: {item['id']})" for item in items]
    return "\n".join(results)

def read_note(note_id):
    data = joplin_request(f"notes/{note_id}", {"fields": "id,title,body"})
    if "error" in data:
        return f"Error: {data['error']}"
    
    title = data.get("title", "Sin título")
    body = data.get("body", "")
    return f"# {title}\n\n{body}"

def list_notebooks():
    data = joplin_request("folders")
    if "error" in data:
        return f"Error: {data['error']}"

    items = data.get("items", [])
    if not items:
        return "No se encontraron libretas."

    results = [f"- {item['title']} (ID: {item['id']})" for item in items]
    return "\n".join(results)

def create_notebook(title):
    title = (title or "").strip()
    if not title:
        return "Error: El título de la libreta es obligatorio."

    response = joplin_request("folders", method="POST", data={"title": title})
    if "error" in response:
        return f"Error: {response['error']}"

    notebook_id = response.get("id", "desconocido")
    return f"Libreta creada: {title} (ID: {notebook_id})"

def create_note(title, body, parent_id):
    parent_id = (parent_id or "").strip()
    if not parent_id:
        return "Error: Es necesario proporcionar el ID de la libreta (parent_id)."

    title = (title or "").strip() or "Sin título"
    body = body or ""

    response = joplin_request(
        "notes",
        method="POST",
        data={
            "title": title,
            "body": body,
            "parent_id": parent_id,
        }
    )

    if "error" in response:
        return f"Error: {response['error']}"

    note_id = response.get("id", "desconocido")
    return f"Nota creada: {title} (ID: {note_id})"

def update_note(note_id, title=None, body=None):
    note_id = (note_id or "").strip()
    if not note_id:
        return "Error: Es necesario proporcionar el ID de la nota."

    payload = {}
    if title is not None:
        payload["title"] = title
    if body is not None:
        payload["body"] = body

    if not payload:
        return "Error: Debes proporcionar al menos un campo a actualizar (title o body)."

    response = joplin_request(f"notes/{note_id}", method="PUT", data=payload)
    if "error" in response:
        return f"Error: {response['error']}"

    return f"Nota actualizada (ID: {note_id})."

# Declaración estática de las herramientas para exponerlas vía MCP
TOOLS = [
    {
        "name": "search_notes",
        "description": "Searches notes in Joplin using a keyword. Returns a list of IDs and titles.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "The word or phrase to search for"}
            },
            "required": ["query"]
        }
    },
    {
        "name": "read_note",
        "description": "Reads the full Markdown content of a specific note given its ID.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "note_id": {"type": "string", "description": "The note ID in Joplin"}
            },
            "required": ["note_id"]
        }
    },
    {
        "name": "list_notebooks",
        "description": "Obtains a list of all notebooks in Joplin.",
        "inputSchema": {
            "type": "object",
            "properties": {}
        }
    },
    {
        "name": "create_notebook",
        "description": "Creates a new notebook in Joplin.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "title": {"type": "string", "description": "Name for the new notebook"}
            },
            "required": ["title"]
        }
    },
    {
        "name": "create_note",
        "description": "Creates a new note inside a given notebook.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "title": {"type": "string", "description": "Title for the new note"},
                "body": {"type": "string", "description": "Markdown content for the note"},
                "parent_id": {"type": "string", "description": "Notebook ID where the note will be stored"}
            },
            "required": ["title", "body", "parent_id"]
        }
    },
    {
        "name": "update_note",
        "description": "Updates the title and/or body of an existing note.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "note_id": {"type": "string", "description": "The note ID in Joplin"},
                "title": {"type": ["string", "null"], "description": "New title (optional)"},
                "body": {"type": ["string", "null"], "description": "New Markdown content (optional)"}
            },
            "required": ["note_id"]
        }
    }
]

def handle_request(msg):
    method = msg.get("method")
    msg_id = msg.get("id")
    
    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {}
                },
                "serverInfo": {
                    "name": "joplin_mcp_raw",
                    "version": "2.1.1"
                }
            }
        }
        
    elif method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {
                "tools": TOOLS
            }
        }
        
    elif method == "tools/call":
        params = msg.get("params", {})
        tool_name = params.get("name")
        args = params.get("arguments", {})
        
        result_text = ""
        is_error = False
        
        if tool_name == "search_notes":
            result_text = search_notes(args.get("query", ""))
        elif tool_name == "read_note":
            result_text = read_note(args.get("note_id", ""))
        elif tool_name == "list_notebooks":
            result_text = list_notebooks()
        elif tool_name == "create_notebook":
            result_text = create_notebook(args.get("title"))
        elif tool_name == "create_note":
            result_text = create_note(
                args.get("title"),
                args.get("body"),
                args.get("parent_id")
            )
        elif tool_name == "update_note":
            result_text = update_note(
                args.get("note_id"),
                args.get("title"),
                args.get("body")
            )
        else:
            result_text = f"Herramienta desconocida: {tool_name}"
            is_error = True
            
        return {
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {
                "content": [
                    {
                        "type": "text",
                        "text": result_text
                    }
                ],
                "isError": is_error
            }
        }
        
    # Las notificaciones (como notifications/initialized, ping, o cancel) no tienen un ID que requiera respuesta directa
    if msg_id is not None:
        return {
            "jsonrpc": "2.0",
            "id": msg_id,
            "error": {
                "code": -32601,
                "message": f"Method {method} not supported"
            }
        }
    return None

def main():
    # Bucle infinito para recibir comandos a través de standard input (stdio)
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
            
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue
            
        response = handle_request(msg)
        if response:
            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()

if __name__ == "__main__":
    main()
