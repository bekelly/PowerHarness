$ErrorActionPreference = 'Stop'

class phUtil {

    [PSCustomObject] MergeJsonObjects([PSCustomObject]$Default, [PSCustomObject]$Override) {
        foreach ($prop in $Override.PSObject.Properties) {
            $name  = $prop.Name
            $value = $prop.Value

            if ($Default.PSObject.Properties.Name -contains $name) {
                # both are objects? recurse
                if ($value -is [PSCustomObject] -and
                    $Default.$name -is [PSCustomObject]) {

                    $Default.$name = $this.MergeJsonObjects($Default.$name, $value)
                }
                else {
                    # override scalar or array
                    $Default.PSObject.Properties[$name].Value = $value
                }
            }
            else {
                # brand-new property → add it
                $Default | Add-Member -MemberType NoteProperty -Name $name -Value $value
            }
        }

        return $Default
    }

}