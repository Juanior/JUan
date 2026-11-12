"""Junta los scripts de src/ en un solo archivo IslaSinSalida.rbxlx que se abre directo en Roblox Studio.

Uso: python3 herramientas/construir_rbxlx.py
"""
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
SRC = RAIZ / "src"
SALIDA = RAIZ / "IslaSinSalida.rbxlx"

contador = 0


def ref():
    global contador
    contador += 1
    return f"RBX{contador:08X}"


def script(clase, nombre, archivo):
    codigo = (SRC / archivo).read_text(encoding="utf-8")
    assert "]]>" not in codigo, f"{archivo} contiene ']]>'"
    return (
        f'<Item class="{clase}" referent="{ref()}"><Properties>'
        f'<string name="Name">{nombre}</string>'
        f'<bool name="Disabled">false</bool>'
        f'<ProtectedString name="Source"><![CDATA[{codigo}]]></ProtectedString>'
        f"</Properties></Item>"
    )


def servicio(clase, hijos=""):
    return (
        f'<Item class="{clase}" referent="{ref()}"><Properties>'
        f'<string name="Name">{clase}</string></Properties>{hijos}</Item>'
    )


partes = [
    servicio("Workspace"),
    servicio("Lighting"),
    servicio("ReplicatedStorage"),
    servicio("ServerScriptService", script("Script", "IslaSinSalida", "IslaSinSalida.server.lua")),
    servicio(
        "StarterPlayer",
        servicio(
            "StarterPlayerScripts",
            script("LocalScript", "Pantalla", "Pantalla.client.lua")
            + script("LocalScript", "CamaraConRaton", "CamaraConRaton.client.lua"),
        ),
    ),
]

xml = (
    '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
    'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
    '<External>null</External><External>nil</External>'
    + "".join(partes)
    + "</roblox>\n"
)
SALIDA.write_text(xml, encoding="utf-8")
print(f"Creado {SALIDA.name}")
