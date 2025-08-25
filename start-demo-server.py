import http.server
import socketserver
import os
import webbrowser
from pathlib import Path

PORT = 8080
DIRECTORY = "demo-server"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

if __name__ == "__main__":
    os.chdir(Path(__file__).parent)
    
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"FormWang Demo Server running at http://localhost:{PORT}")
        print(f"Press Ctrl+C to stop the server")
        
        # Try to open browser
        try:
            webbrowser.open(f"http://localhost:{PORT}")
        except:
            pass
            
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")
