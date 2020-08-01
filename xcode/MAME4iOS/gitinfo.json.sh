GIT_COMMIT=`git rev-parse HEAD`
GIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
GIT_DESCRIBE=`git describe --tags`
GIT_DATE=`date -R`
GIT_TIMESTAMP=`date +%s`

echo "{"
echo "\t\"git-commit\": \"$GIT_COMMIT\","
echo "\t\"git-branch\": \"$GIT_BRANCH\","
echo "\t\"git-describe\": \"$GIT_DESCRIBE\","
echo "\t\"git-date\": \"$GIT_DATE\","
echo "\t\"git-timestamp\": $GIT_TIMESTAMP"
echo "}"
