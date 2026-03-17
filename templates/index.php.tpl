<?php
/**
 * Dashboard de Desenvolvimento PHP
 * Local: ~/workspace/www/html/index.php
 */

// 1. Tenta ler as versões do arquivo .env da stack
$envFile = __DIR__ . "/../../docker/.env";
$phpVersions = [];

if (file_exists($envFile)) {
    $envContent = file_get_contents($envFile);
    if (preg_match("/PHP_VERSIONS=(.*)/", $envContent, $matches)) {
        $phpVersions = explode(" ", trim($matches[1]));
    }
}

// Fallback caso não consiga ler o .env
if (empty($phpVersions)) {
    $phpVersions = ["7.4", "8.1", "8.2", "8.3"];
}

// Função para verificar se o subdomínio está acessível (opcional/rápida)
function checkStatus($version)
{
    $host = "php" . str_replace(".", "", $version) . ".localhost";
    return "http://$host";
}
?>
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dev Panel | PHP Stack</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body class="bg-slate-900 text-slate-200 font-sans min-h-screen flex flex-col items-center justify-center p-6">

    <div class="max-w-4xl w-full">
        <div class="text-center mb-10">
            <h1 class="text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-emerald-400 mb-2">
                PHP Dev Stack
            </h1>
            <p class="text-slate-400 uppercase tracking-widest text-sm">Ambiente de Desenvolvimento Docker</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-6">
            <?php foreach ($phpVersions as $version):

                $vClean = str_replace(".", "", $version);
                $url = "http://php$vClean.localhost/info.php";
                ?>
                <a href="<?php echo $url; ?>" target="_blank"
                   class="group block p-6 bg-slate-800 border border-slate-700 rounded-2xl hover:border-blue-500 transition-all duration-300 shadow-xl hover:shadow-blue-500/10">
                    <div class="flex items-center justify-between">
                        <div>
                            <span class="text-xs font-bold text-blue-400 uppercase tracking-tight">Versão Instalada</span>
                            <h2 class="text-3xl font-bold text-white mt-1">PHP <?php echo $version; ?></h2>
                        </div>
                        <div class="bg-slate-700 p-4 rounded-xl group-hover:bg-blue-600 transition-colors">
                            <i class="fa-brands fa-php text-3xl text-white"></i>
                        </div>
                    </div>
                    <div class="mt-4 flex items-center text-slate-400 text-sm">
                        <i class="fa-solid fa-link mr-2"></i>
                        <span>php<?php echo $vClean; ?>.localhost</span>
                    </div>
                </a>
            <?php
            endforeach; ?>
        </div>

        <div class="mt-12 grid grid-cols-1 md:grid-cols-3 gap-4 text-center">
            <div class="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                <i class="fa-solid fa-database text-emerald-400 mb-2"></i>
                <p class="text-xs text-slate-500 uppercase">MariaDB Host</p>
                <p class="font-mono text-sm">localhost:3306</p>
            </div>
            <div class="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                <i class="fa-solid fa-folder-open text-amber-400 mb-2"></i>
                <p class="text-xs text-slate-500 uppercase">Projetos em</p>
                <p class="font-mono text-sm">~/workspace/www/html</p>
            </div>
            <div class="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                <i class="fa-solid fa-terminal text-blue-400 mb-2"></i>
                <p class="text-xs text-slate-500 uppercase">Comando Global</p>
                <p class="font-mono text-sm">mydocker</p>
            </div>
        </div>
    </div>

</body>
</html>
