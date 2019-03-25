# See https://docs.microsoft.com/en-gb/azure/devops/pipelines/languages/anaconda.

if [ "$(uname)" == "Darwin" ]; then
    echo "##vso[task.prependpath]$CONDA/bin"
    sudo chown -R $USER $CONDA
elif [ "$(uname)" == "Linux" ]; then
    echo "##vso[task.prependpath]/usr/share/miniconda/bin"
    sudo chown -R $USER /usr/share/miniconda
else
    echo "##vso[task.prependpath]$CONDA"
    echo "##vso[task.prependpath]$CONDA\Scripts"
fi
