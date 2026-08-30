package templates

#MonitoringDashboards: {
	payments: """
		{
		  "annotations": {
		    "list": [
		      {
		        "builtIn": 1,
		        "datasource": {
		          "type": "grafana",
		          "uid": "-- Grafana --"
		        },
		        "enable": true,
		        "hide": true,
		        "iconColor": "rgba(0, 211, 255, 1)",
		        "name": "Annotations & Alerts",
		        "type": "dashboard"
		      }
		    ]
		  },
		  "editable": true,
		  "fiscalYearStartMonth": 0,
		  "graphTooltip": 0,
		  "id": 204,
		  "links": [],
		  "liveNow": false,
		  "panels": [
		    {
		      "collapsed": true,
		      "gridPos": {
		        "h": 1,
		        "w": 24,
		        "x": 0,
		        "y": 0
		      },
		      "id": 36,
		      "panels": [
		        {
		          "datasource": {
		            "type": "postgres",
		            "uid": "postgres_uid"
		          },
		          "fieldConfig": {
		            "defaults": {
		              "thresholds": {
		                "mode": "absolute",
		                "steps": [
		                  {
		                    "color": "green"
		                  },
		                  {
		                    "color": "red",
		                    "value": 80
		                  }
		                ]
		              }
		            },
		            "overrides": []
		          },
		          "gridPos": {
		            "h": 4,
		            "w": 24,
		            "x": 0,
		            "y": 1
		          },
		          "id": 35,
		          "options": {
		            "autoScroll": false,
		            "displayMode": "button",
		            "favorites": false,
		            "filter": false,
		            "groupSelection": false,
		            "header": true,
		            "padding": 10,
		            "showName": false,
		            "statusSort": false,
		            "sticky": false,
		            "variable": "merchant_id"
		          },
		          "title": "Merchant ID",
		          "type": "volkovlabs-variable-panel"
		        }
		      ],
		      "title": "Success Rate Trends",
		      "type": "row"
		    }
		  ],
		  "title": "Hyperswitch Payments Dashboard"
		}
		"""
	podUsage: """
		{
		  "annotations": {
		    "list": [
		      {
		        "builtIn": 1,
		        "datasource": {
		          "type": "grafana",
		          "uid": "-- Grafana --"
		        },
		        "enable": true,
		        "hide": true,
		        "iconColor": "rgba(0, 211, 255, 1)",
		        "name": "Annotations & Alerts",
		        "type": "dashboard"
		      }
		    ]
		  },
		  "description": "Kubernetes pod resource usage",
		  "editable": true,
		  "fiscalYearStartMonth": 0,
		  "graphTooltip": 1,
		  "links": [],
		  "liveNow": false,
		  "panels": [
		    {
		      "collapsed": false,
		      "gridPos": {
		        "h": 1,
		        "w": 24,
		        "x": 0,
		        "y": 0
		      },
		      "id": 50,
		      "panels": [],
		      "title": "Cluster Overview",
		      "type": "row"
		    }
		  ],
		  "title": "Hyperswitch Pod Usage Dashboard"
		}
		"""
}
