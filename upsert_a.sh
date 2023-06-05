#!/bin/bash
#
# IP アドレスを特定の FQDN に割り当て
#
# - upsert_a.sh <HOSTED_ZONE_ID> <HOSTNAME> <IPV4>
#

# 引数チェック (数のみ)
# - https://bioinfo-dojo.net/2018/02/21/shellscript_args/#toc2
if [ $# != 3 ]; then
    echo >&2 "ERROR: Args count error."
    exit 1
fi

# 以下で HOSTED_ZONE_ID を確認
# https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones
# aws route53 list-hosted-zones
#HOSTED_ZONE_ID="Z3T2KC0KGMQA00"  # akoba.xyz
HOSTED_ZONE_ID=$1

# ホスト名
HOSTNAME=$2

# IP アドレス
IPV4=$3

# ドメイン取得
DOMAIN=$(aws route53 get-hosted-zone --id $HOSTED_ZONE_ID --query "HostedZone.Name" | tr -d '"')
# エラー処理は甘め。tr コマンドの終了ステータスになる。
echo $?
echo $DOMAIN

# https://atmarkit.itmedia.co.jp/aig/06network/fqdn.html
FQDN="$HOSTNAME.$DOMAIN"
echo $FQDN

# 一時ファイルは消さない
tmpfile=$(mktemp)

cat <<EOF > $tmpfile
{
  "Comment": "UPSERT a record ",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$FQDN",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{ "Value": "$IPV4" }]
    }
  }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://$tmpfile
# ↓ココまではしない
# https://hacknote.jp/archives/35775/
if [ $? -ne 0 ]; then
    echo >&2 "ERROR: aws route53 command error."
    exit 1
fi
