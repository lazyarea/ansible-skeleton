#! /usr/bin/perl

system("rm -rf doc");
system("mkdir doc");

my $ifh;
open($ifh, "pod2html --title 'Kyoto Cabinet' KyotoCabinet.pod |");
my $ofh;
open($ofh, ">doc/index.html");

while (defined(my $line = <$ifh>)) {
    chomp($line);
    next if ($line =~ /<link /);
    $line =~ s/ +style="[^"]*"//;
    $line =~ s/^<p>&#10;/<p>/;
    $line =~ s/^&#10;/<br \/>/g;
    $line =~ s/\@param +(\w+) +/<strong class="tag">\@param<\/strong> <var>$1<\/var> /g;
    $line =~ s/\@(\w+) +/<strong class="tag">\@$1<\/strong> /g;
    if ($line =~ /<\/head>/) {
        my $str = "<meta http-equiv=\"content-style-type\" content=\"text/css\" />\n" .
            "<style type=\"text/css\">body {\n" .
            "  padding: 1em 2em;\n" .
            "  background: #f8f8f8 none;\n" .
            "  color: #222222;\n" .
            "}\n" .
            "pre {\n" .
            "  padding: 0.2em 0em;\n" .
            "  background: #eeeef8 none;\n" .
            "  border: 1px solid #ddddee;\n" .
            "  font-size: 95%;\n" .
            "}\n" .
            "h1,h2,h3,dt {\n" .
            "  color: #111111;\n" .
            "}\n" .
            "dd p {\n" .
            "  margin: 0.4em 0em 1.0em 0em;\n" .
            "  padding: 0em;\n" .
            "  color: #333333;\n" .
            "}\n" .
            "dd p:first-line {\n" .
            "  color: #111111;\n" .
            "}\n" .
            "strong.tag {\n" .
            "  margin-left: 0.5em;\n" .
            "  padding-top: 0.5em;\n" .
            "  font-size: 90%;\n" .
            "  color: #222222;\n" .
            "}\n" .
            "var {\n" .
            "  font-weight: bold;\n" .
            "}\n" .
            "</style>\n";
        print $ofh ($str);
    }
    printf $ofh ("%s\n", $line);
}

close($ofh);
close($ifh);
