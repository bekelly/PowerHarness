$ErrorActionPreference = 'Stop'

class phEmailTemplater {
    [System.Text.StringBuilder] $Body = [System.Text.StringBuilder]::new()
    [string] $TemplatePath = ""

    #----------------------------------------------------------------------------------------------
    # constructors
    #----------------------------------------------------------------------------------------------
    phEmailTemplater() {
        $this.TemplatePath = Join-Path $PSScriptRoot "../resources/EmailTemplate.html"
    }

    phEmailTemplater([string]$templatePath) {
        $this.TemplatePath = $templatePath
    }

    #----------------------------------------------------------------------------------------------
    # Private helper method for HTML escaping and template application
    #----------------------------------------------------------------------------------------------
    hidden [phEmailTemplater] AddHtml([string]$template, [string]$content) {
        # $escapedContent = [System.Net.WebUtility]::HtmlEncode($content)
        $escapedContent = $content # no HTML encoding (for now)
        $html = $template -replace '\{content\}', $escapedContent
        $this.Body.AppendLine($html) | Out-Null
        return $this
    }

    #----------------------------------------------------------------------------------------------
    #----------------------------------------------------------------------------------------------
    [phEmailTemplater] AddTitle([string]$content) {
        return $this.AddHtml("<h1>{content}</h1>", $content)
    }

    [phEmailTemplater] AddTitleChipGreen([string]$content) {
        return $this.AddHtml("<h1 class='title-chip-green'>{content}</h1>", $content)
    }

    [phEmailTemplater] AddTitleChipBlue([string]$content) {
        return $this.AddHtml("<h1 class='title-chip-blue'>{content}</h1>", $content)
    }

    [phEmailTemplater] AddTitleChipBlack([string]$content) {
        return $this.AddHtml("<h1 class='title-chip-black'>{content}</h1>", $content)
    }

    [phEmailTemplater] AddTitleChipRed([string]$content) {
        return $this.AddHtml("<h1 class='title-chip-red'>{content}</h1>", $content)
    }

    [phEmailTemplater] AddCode([string]$lang, [string]$content) {
        # we will add syntax highlighting in the next phase
        return $this.AddHtml("<pre class='code'><code>{content}</code></pre>", $content)
    }

    [phEmailTemplater] AddMonoBlock([string]$content) {
        return $this.AddHtml("<pre class='code'><code>{content}</code></pre>", $content)
    }

    [phEmailTemplater] AddLogContent([string]$content) {
        return $this.AddHtml("<div class='code'><code>{content}</code></div>", $content)
    }

    [phEmailTemplater] AddTable([string]$htmlTable) {
        return $this.AddHtml("<div class='table-container'>{content}</div>", $htmlTable)
    }

    [phEmailTemplater] AddPlain([string]$content) {
        return $this.AddHtml("<div class='plain'>{content}</div>", $content)
    }

    [phEmailTemplater] Reset() {
        $this.Body.Clear()
        return $this
    }

    #----------------------------------------------------------------------------------------------
    # GetBody
    #----------------------------------------------------------------------------------------------
    [string] GetBody() {
        return $this.ApplyTemplate($this.TemplatePath, @{ body = $this.Body.ToString() })
    }

    #----------------------------------------------------------------------------------------------
    # ApplyTemplate overloads
    #----------------------------------------------------------------------------------------------
    [string] ApplyTemplate([hashtable]$placeholders) {
        return $this.ApplyTemplate($this.TemplatePath, $placeholders)
    }

    [string] ApplyTemplate([string]$templatePath, [hashtable]$placeholders) {

        #------------------------------------------------------------------------------------------
        # validate the template path
        #------------------------------------------------------------------------------------------
        if (-not (Test-Path $templatePath)) {
            throw "Template file not found: $templatePath"
        }

        #------------------------------------------------------------------------------------------
        # load the file
        #------------------------------------------------------------------------------------------
        $templateContent = Get-Content -Path $templatePath -Raw

        #------------------------------------------------------------------------------------------
        # do the replacements
        #------------------------------------------------------------------------------------------
        foreach ($key in $placeholders.Keys) {
            $placeholder = "%$key%"
            $value = $placeholders[$key]
            $templateContent = $templateContent.Replace($placeholder, $value)
        }

        #------------------------------------------------------------------------------------------
        # give 'em what we've got
        #------------------------------------------------------------------------------------------
        return $templateContent

    }
}