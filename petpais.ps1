<#
    Identificación del país de origen
    Se consulta la dirección de correo electrónico asociada al userID del peticionario
    Si termina en .xx -> petición país A
    Si termina en .yy -> petición país B
    Si el usuario ya no está en el AD -> mala suerte
#>
Import-Csv .\export.csv -Delimiter "," | ForEach-Object {
    #Creamos el objeto para almacenar los resultados
    $resultado = New-Object -TypeName PSObject
    $resultado | Add-Member -MemberType NoteProperty -Name petID -Value $_.id
    $resultado | Add-Member -MemberType NoteProperty -Name userid -Value $_.requestor    
    #Buscamos el userID en el directorio activo
    Try {
        $usuario = Get-ADUser -Identity $_.requestor -Properties *
        #Algunos usuarios tienen el campo correo vacío
        if (!$usuario.mail){
            $usuario.mail = "Usuario sin correo en el AD"
        }
    }
    #Controlamos el error, si todo va bien el único error será que no se encuentra el usuario
    #TODO: Controlar ese error *específicamente*
    Catch {
        $usuario.mail = "Usuario no encontrado en el AD"
    }
    $resultado | Add-Member -MemberType NoteProperty -Name correo -Value $usuario.mail
    #Regex para discernir el país en función de cómo termina la dirección de correo
    if ($usuario.mail -match ".xx$") {
        $resultado | Add-Member -MemberType NoteProperty -Name pais -Value "XX"
    }
    elseif ($usuario.mail -match ".yy$") {
        $resultado | Add-Member -MemberType NoteProperty -Name pais -Value "YY"
    }
    #Si no tiene correo intentamos sacar el pais de su perfil del AD
    elseif ($usuario.mail -match "Usuario sin correo en el AD") {
        if ($usuario.c -eq "XX"){
            $resultado | Add-Member -MemberType NoteProperty -Name pais -Value "XX _by C"
        }
        elseif($usuario.c -eq "YY"){
            $resultado | Add-Member -MemberType NoteProperty -Name pais -Value "YY _by C"
        }
        else {
            $resultado | Add-Member -MemberType NoteProperty -Name pais -Value "ND _by C"
        }
    }
    else {
        $resultado | Add-Member -MemberType NoteProperty -Name pais -Value "ND"
    }
    #Extracción de los datos
    $resultado | Select-Object -Property petID,userid,correo,pais | Export-Csv .\peticiones_por_pais_v2.csv -Append
}
