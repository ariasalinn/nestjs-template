#!/bin/sh
curl -f -H "Authorization: Bearer ${HEALTH_TOKEN}" http://localhost:3000/api/v1/health || exit 1
